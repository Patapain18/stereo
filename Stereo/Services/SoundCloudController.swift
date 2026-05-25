//
//  SoundCloudController.swift
//  Stereo · Services/SoundCloudController.swift
//
//  Lecteur SoundCloud intégré via WKWebView caché qui charge le SoundCloud
//  Widget API officiel. Communication JS ↔ Swift via WKScriptMessageHandler.
//
//  Fonctionnement :
//  — Au démarrage, on charge un mini HTML qui contient un <iframe> du widget SC
//    et un script qui bind les events (READY, PLAY, PAUSE, PLAY_PROGRESS, FINISH)
//  — Les events sont remontés en Swift via `webkit.messageHandlers.scBridge.postMessage`
//  — Les commandes (play, pause, seek, load) sont exécutées via `evaluateJavaScript`
//  — Le webview n'est jamais affiché à l'écran (il vit en mémoire)
//
//  ⚠️ Limites :
//  — Si SoundCloud change leur Widget API, ça casse
//  — La position remontée par PLAY_PROGRESS est précise mais limitée à ~4Hz
//  — Pas de réelle prefetch/queue : on ne joue qu'un track à la fois
//

import Foundation
import WebKit
import Observation
import AppKit

@MainActor
@Observable
final class SoundCloudController: NSObject {

    // MARK: — État observable

    private(set) var isReady: Bool = false
    private(set) var isPlaying: Bool = false
    private(set) var position: Double = 0     // sec
    private(set) var duration: Double = 0     // sec
    private(set) var currentTrack: Track? = nil

    // MARK: — Internals

    private var webView: WKWebView!
    private var hostWindow: NSWindow?
    private var pendingTrack: Track? = nil
    private var pendingPlay: Bool = false

    /// Closures externes (le PlaybackRouter s'inscrit dessus pour propager dans PlayerState)
    var onTrackChanged: ((Track?) -> Void)?
    var onPlayStateChanged: ((Bool) -> Void)?
    var onProgress: ((Double, Double) -> Void)?  // (position, duration)
    var onFinish: (() -> Void)?

    override init() {
        super.init()
        setupWebView()
    }

    // MARK: — Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        userContent.add(MessageRelay(controller: self), name: "scBridge")
        config.userContentController = userContent

        // Autoplay audio sans gesture utilisateur
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 200), configuration: config)

        // Attache le webview à une fenêtre offscreen pour que macOS ne suspende
        // pas son JS / sa lecture audio. Sans ça, le widget se bloque silencieusement.
        let window = NSWindow(
            contentRect: NSRect(x: -10000, y: -10000, width: 320, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.contentView = webView
        window.orderFrontRegardless()
        self.hostWindow = window

        webView.loadHTMLString(htmlContent, baseURL: URL(string: "https://w.soundcloud.com")!)
        print("🎵 SC: WebView setup, hostWindow shown offscreen")
    }

    private var htmlContent: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>html,body{margin:0;padding:0;background:#000;}</style>
        </head>
        <body>
          <iframe id="sc-player" width="100%" height="166"
                  src="about:blank"
                  frameborder="0"
                  allow="autoplay"></iframe>
          <script src="https://w.soundcloud.com/player/api.js"></script>
          <script>
            (function() {
              const iframe = document.getElementById('sc-player');
              let widget = null;

              function send(event, payload) {
                try {
                  window.webkit.messageHandlers.scBridge.postMessage(
                    Object.assign({event: event}, payload || {})
                  );
                } catch (e) {}
              }

              // Une fois l'iframe initialement loadée (about:blank), on note que la
              // page hôte est prête à recevoir des commandes load(url).
              send('host_ready');

              window.scLoad = function(url) {
                // Set src de l'iframe vers le widget SC pour cette URL
                iframe.src = 'https://w.soundcloud.com/player/?url=' + encodeURIComponent(url)
                  + '&auto_play=true&visual=false&show_user=true&hide_related=true&show_comments=false';

                iframe.onload = function() {
                  widget = SC.Widget(iframe);
                  widget.bind(SC.Widget.Events.READY, function() {
                    widget.getCurrentSound(function(sound) {
                      send('ready', sound ? {
                        title: sound.title || '',
                        author: (sound.user && sound.user.username) || '',
                        duration: (sound.duration || 0) / 1000,
                        artwork: sound.artwork_url || ''
                      } : {});
                    });
                  });
                  widget.bind(SC.Widget.Events.PLAY, function() { send('play'); });
                  widget.bind(SC.Widget.Events.PAUSE, function() { send('pause'); });
                  widget.bind(SC.Widget.Events.PLAY_PROGRESS, function(d) {
                    send('progress', { position: (d.currentPosition || 0) / 1000 });
                  });
                  widget.bind(SC.Widget.Events.FINISH, function() { send('finish'); });
                  widget.bind(SC.Widget.Events.ERROR, function(e) { send('error', { message: String(e) }); });
                };
              };

              window.scPlay = function() { if (widget) widget.play(); };
              window.scPause = function() { if (widget) widget.pause(); };
              window.scSeek = function(sec) { if (widget) widget.seekTo((sec || 0) * 1000); };
              window.scSetVolume = function(v) { if (widget) widget.setVolume(Math.round((v || 0) * 100)); };
            })();
          </script>
        </body>
        </html>
        """
    }

    // MARK: — Commandes publiques

    func load(_ track: Track) {
        guard track.source == .soundcloud, let url = track.externalURL else {
            print("⚠️ SC load: track invalide (source=\(track.source) externalURL=\(String(describing: track.externalURL)))")
            return
        }
        currentTrack = track
        onTrackChanged?(track)

        if isReady {
            print("🎵 SC: scLoad('\(url.absoluteString)')")
            evaluate("scLoad('\(escape(url.absoluteString))')")
        } else {
            print("🎵 SC: pas encore ready, bufferise le track")
            pendingTrack = track
        }
    }

    func play() {
        guard isReady, currentTrack != nil else { return }
        evaluate("scPlay()")
    }

    func pause() {
        guard isReady else { return }
        evaluate("scPause()")
    }

    func togglePlay() {
        if isPlaying { pause() } else { play() }
    }

    func seek(toSeconds sec: Double) {
        guard isReady else { return }
        evaluate("scSeek(\(sec))")
    }

    // MARK: — Réception des events JS

    fileprivate func handleEvent(_ name: String, payload: [String: Any]) {
        switch name {
        case "host_ready":
            isReady = true
            print("🎵 SC: host page ready")
            // Si un track a été demandé avant ready, on le charge maintenant
            if let pending = pendingTrack {
                pendingTrack = nil
                load(pending)
            }

        case "ready":
            print("🎵 SC: widget ready for track — title=\(payload["title"] ?? "?")")
            // Mise à jour des métadonnées avec ce que retourne SoundCloud
            // (souvent plus précis que oEmbed)
            if var track = currentTrack {
                if let title = payload["title"] as? String, !title.isEmpty {
                    track.title = title
                }
                if let author = payload["author"] as? String, !author.isEmpty {
                    track.artist = author
                }
                if let dur = payload["duration"] as? Double, dur > 0 {
                    track.duration = dur
                    duration = dur
                }
                if let artwork = payload["artwork"] as? String,
                   !artwork.isEmpty {
                    let upgraded = artwork.replacingOccurrences(of: "-large.jpg", with: "-t500x500.jpg")
                    if let url = URL(string: upgraded) {
                        track.artworkURL = url
                    }
                }
                currentTrack = track
                onTrackChanged?(track)
            }

            // Force la lecture si auto_play=true du widget URL n'a pas suffi
            // (politique de WebKit sur l'autoplay audio peut bloquer)
            evaluate("scPlay()")

        case "play":
            print("🎵 SC: PLAY event")
            isPlaying = true
            onPlayStateChanged?(true)

        case "pause":
            print("🎵 SC: PAUSE event")
            isPlaying = false
            onPlayStateChanged?(false)

        case "progress":
            if let pos = payload["position"] as? Double {
                position = pos
                onProgress?(pos, duration)
            }

        case "finish":
            print("🎵 SC: FINISH event")
            isPlaying = false
            onPlayStateChanged?(false)
            onFinish?()

        case "error":
            print("⚠️ SC Widget error:", payload["message"] ?? "")

        default:
            print("🎵 SC: unknown event:", name)
        }
    }

    // MARK: — Helpers

    private func evaluate(_ js: String) {
        webView.evaluateJavaScript(js) { _, error in
            if let error {
                print("⚠️ SC JS error: \(error.localizedDescription)")
            }
        }
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "'", with: "\\'")
    }
}

// MARK: — Message relay (évite cycle de rétention avec WKScriptMessageHandler)

private final class MessageRelay: NSObject, WKScriptMessageHandler {
    weak var controller: SoundCloudController?

    init(controller: SoundCloudController) {
        self.controller = controller
        super.init()
    }

    nonisolated func userContentController(_ userContentController: WKUserContentController,
                                            didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let event = body["event"] as? String else { return }
        Task { @MainActor [weak self] in
            self?.controller?.handleEvent(event, payload: body)
        }
    }
}
