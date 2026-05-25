//
//  SidebarView.swift
//  Stereo · Views/Sidebar/SidebarView.swift
//
//  Sidebar refondue : design dense + harmonieux, icônes SF cohérentes,
//  sélection plus discrète (bande gauche ocre + halo subtil), footer
//  compact.
//
//  Principe directeur : laisser respirer le titre et les playlists,
//  resserrer la nav primaire pour réduire la "scroll fatigue" verticale.
//

import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    var body: some View {
        @Bindable var app = app

        VStack(alignment: .leading, spacing: 14) {
            header

            navItems
                .padding(.horizontal, 6)

            playlistsSection

            Spacer(minLength: 0)

            footerControls
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.background)
        .scrollContentBackground(.hidden)
        .toolbarBackground(Theme.background, for: .windowToolbar)
    }

    // MARK: — Header

    private var header: some View {
        @Bindable var app = app
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("ma")
                        .font(Theme.scribble(size: 24))
                        .foregroundStyle(Theme.inkLight)
                    Text("stéréo")
                        .font(Theme.scribble(size: 28))
                        .foregroundStyle(Theme.inkLight)
                        .overlay(
                            UnderlineSketch()
                                .stroke(Theme.ocre, lineWidth: 1.4)
                                .frame(height: 6)
                                .offset(y: 5),
                            alignment: .bottom
                        )
                }
                Text(greeting)
                    .font(Theme.typewriter(size: 9.5))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textMute)
                    .padding(.top, 2)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    app.sidebarVisible = false
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Theme.textMute)
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.pressFeedback)
            .help("Masquer la sidebar (Cmd+Shift+S)")
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    /// Greeting court basé sur l'heure courante — plus poétique que
    /// l'heure brute sans tomber dans l'over-engineering.
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        let label: String
        switch h {
        case 5..<11:  label = "café matinal"
        case 11..<14: label = "pause midi"
        case 14..<18: label = "session après-midi"
        case 18..<22: label = "session du soir"
        default:      label = "session nocturne"
        }
        return "\(label) · \(h)h"
    }

    // MARK: — Nav

    private var navItems: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 1) {
            ForEach(Page.allCases, id: \.self) { page in
                navRow(page: page, current: app.page == page) {
                    app.page = page
                    app.pageArg = nil
                }
            }
        }
    }

    private func navRow(page: Page, current: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: page.icon)
                    .font(.system(size: 13, weight: current ? .medium : .regular))
                    .foregroundStyle(current ? Theme.ocre : Theme.textMute)
                    .frame(width: 18, alignment: .center)

                Text(page.title.lowercased())
                    .font(Theme.hand(size: 16))
                    .foregroundStyle(current ? Theme.inkLight : Theme.textSoft)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(current ? Theme.ocre.opacity(0.07) : .clear)
            )
            .overlay(
                Rectangle()
                    .fill(current ? Theme.ocre : .clear)
                    .frame(width: 2.5)
                    .padding(.vertical, 6),
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: — Playlists

    private var playlistsSection: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("MES PLAYLISTS")
                    .font(Theme.typewriter(size: 9.5))
                    .tracking(1.6)
                    .foregroundStyle(Theme.textMute)
                Text("·")
                    .font(Theme.typewriter(size: 9.5))
                    .foregroundStyle(Theme.textFaint)
                Text("\(library.playlists.count)")
                    .font(Theme.typewriter(size: 9.5))
                    .foregroundStyle(Theme.textFaint)
                Spacer()
            }
            .padding(.horizontal, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(library.playlists.prefix(20)) { pl in
                        playlistRow(pl)
                    }
                }
            }
            .frame(maxHeight: 260)
        }
    }

    private func playlistRow(_ pl: PlaylistRef) -> some View {
        @Bindable var app = app
        let isActive = app.page == .playlists && app.pageArg == pl.id
        return Button {
            app.page = .playlists
            app.pageArg = pl.id
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 10))
                    .foregroundStyle(isActive ? Theme.ocre : Theme.ocre.opacity(0.55))
                    .frame(width: 14)
                Text(pl.name)
                    .font(Theme.hand(size: 13.5))
                    .foregroundStyle(isActive ? Theme.inkLight : Theme.textSoft)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text("\(pl.trackCount)")
                    .font(Theme.typewriter(size: 9))
                    .foregroundStyle(Theme.textFaint)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Theme.ocre.opacity(0.07) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: — Footer

    private var footerControls: some View {
        @Bindable var app = app
        return VStack(spacing: 10) {
            Rectangle()
                .fill(Theme.border.opacity(0.6))
                .frame(height: 1)

            HStack(spacing: 8) {
                ThemeToggleButton()

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        app.radioVisible.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("panneau")
                            .font(Theme.hand(size: 13))
                            .foregroundStyle(Theme.textSoft)
                        Image(systemName: "sidebar.right")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(app.radioVisible ? Theme.ocre : Theme.textMute)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(app.radioVisible ? Theme.ocre.opacity(0.07) : .clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(app.radioVisible ? "Masquer le panneau" : "Afficher le panneau")
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: — Underline sketch (sous le titre)

private struct UnderlineSketch: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 2, y: rect.midY))
            p.addQuadCurve(
                to: CGPoint(x: rect.width / 2, y: rect.midY),
                control: CGPoint(x: rect.width / 4, y: rect.midY - 1)
            )
            p.addQuadCurve(
                to: CGPoint(x: rect.width - 2, y: rect.midY),
                control: CGPoint(x: rect.width * 0.75, y: rect.midY + 1.5)
            )
        }
    }
}

// MARK: — Theme toggle button

private struct ThemeToggleButton: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                app.isNightMode.toggle()
            }
        } label: {
            Image(systemName: app.isNightMode ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSoft)
                .frame(width: 28, height: 28)
                .background(
                    Circle().stroke(Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(app.isNightMode ? "Passer en mode jour" : "Passer en mode nuit")
    }
}
