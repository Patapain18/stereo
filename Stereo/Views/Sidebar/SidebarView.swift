//
//  SidebarView.swift
//  Stereo · Views/Sidebar/SidebarView.swift
//
//  Sprint 4 polish : sidebar refondue avec titre scribble + nav avec icônes
//  manuscrites + section sources de filtrage + theme toggle. Inspirée de la
//  Sidebar de hifi-radio.jsx.
//

import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var app
    @Environment(LibraryStore.self) private var library

    var body: some View {
        @Bindable var app = app

        VStack(alignment: .leading, spacing: 18) {
            header

            navItems
                .padding(.horizontal, 8)

            playlistsSection

            Spacer(minLength: 0)

            footerControls
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: — Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("ma")
                    .font(Theme.scribble(size: 26))
                    .foregroundStyle(Theme.inkLight)
                Text("stéréo")
                    .font(Theme.scribble(size: 30))
                    .foregroundStyle(Theme.inkLight)
                    .overlay(
                        UnderlineSketch()
                            .stroke(Theme.ocre, lineWidth: 1.4)
                            .frame(height: 6)
                            .offset(y: 6),
                        alignment: .bottom
                    )
            }
            Text("café à 17h")
                .font(Theme.typewriter(size: 10))
                .tracking(1)
                .foregroundStyle(Theme.textMute)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    // MARK: — Nav

    private var navItems: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 2) {
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
            HStack(spacing: 12) {
                Text(page.glyph)
                    .font(Theme.scribble(size: 22))
                    .foregroundStyle(current ? Theme.inkLight : Theme.textMute)
                    .frame(width: 22, alignment: .center)
                Text(page.title.lowercased())
                    .font(Theme.hand(size: 17))
                    .foregroundStyle(current ? Theme.inkLight : Theme.textMute)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(current ? Theme.surfaceHover : .clear)
            )
            .overlay(
                Rectangle()
                    .fill(current ? Theme.ocre.opacity(0.7) : .clear)
                    .frame(width: 2)
                    .padding(.vertical, 4),
                alignment: .leading
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: — Playlists

    private var playlistsSection: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("MES PLAYLISTS")
                    .font(Theme.typewriter(size: 10))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMute)
                Spacer()
                Text("\(library.playlists.count)")
                    .font(Theme.typewriter(size: 10))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(.horizontal, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(library.playlists.prefix(20)) { pl in
                        Button {
                            app.page = .playlists
                            app.pageArg = pl.id
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.ocre.opacity(0.7))
                                    .frame(width: 18)
                                Text(pl.name)
                                    .font(Theme.hand(size: 14))
                                    .foregroundStyle(Theme.textSoft)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(pl.trackCount)")
                                    .font(Theme.typewriter(size: 9))
                                    .foregroundStyle(Theme.textFaint)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 280)
        }
    }

    // MARK: — Footer

    private var footerControls: some View {
        @Bindable var app = app
        return VStack(spacing: 0) {
            Divider()
                .background(Theme.border)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                ThemeToggleButton()

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        app.radioVisible.toggle()
                    }
                } label: {
                    Text(app.radioVisible ? "panneau ▸" : "◂ panneau")
                        .font(Theme.hand(size: 13))
                        .foregroundStyle(Theme.inkLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
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
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkLight)
                .frame(width: 32, height: 32)
                .background(
                    Circle().stroke(Theme.borderStrong, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .help(app.isNightMode ? "Passer en mode jour" : "Passer en mode nuit")
    }
}

// MARK: — Page glyph (icône scribble)

extension Page {
    var glyph: String {
        switch self {
        case .library:   return "♪"
        case .search:    return "⌕"
        case .favorites: return "♥"
        case .playlists: return "≡"
        }
    }
}
