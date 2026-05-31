//
//  ToolBarHeaderScrollEffectDemoView.swift
//  animation
//
//  Learning point
//  ──────────────
//  App Store product page style: as the user scrolls past a trigger
//  offset, the navigation bar morphs in a small icon + title (the
//  product hero) on the leading side and an "icloud download" /
//  "Open" action on the trailing side. The "icloud → Open" swap is
//  itself an animated content transition.
//
//  Key APIs
//  ────────
//  • `.appStoreStyleToolBar(triggerOffset:before/afterTrailingContent:
//    before/afterCenterContent:onStatusChanged:)` — project's custom
//    modifier that wraps `.onGeometryChange` on the scroll view and
//    emits a status callback at the threshold. (See its definition
//    in the project for the actual implementation.)
//  • `ToolbarButtonStyleiOS26(isTinted:)` — project's custom button
//    style; `isTinted: true` is the green "Open" pill, default is the
//    glass capsule.
//  • `.opacity` + `.frame(width:)` swap — the "icloud → Open" trick:
//    both buttons exist in a ZStack, the inactive one collapses to
//    width 0 while the active one fades in.
//
//  How to apply
//  ────────────
//  Reach for this when the toolbar should mirror a hero element from
//  the screen below it (icon, person, product). Drive everything from
//  ONE scroll threshold (`triggerOffset`) so the morph fires at the
//  exact same moment for every visual element.
//
//  See also
//  ────────
//  • CustomToolBarIOS26.swift — the same idea, but per-element
//    triggers (each piece has its own `.onGeometryChange`); use that
//    when elements should fade in independently rather than together.
//  • ToolBar+NativeAPI.swift — when no scroll morph is needed at all.
//

import SwiftUI

struct ToolBarHeaderScrollEffectDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("MockView") {
                    ToolBarHeaderScrollEffectDetailView()
                }
            }
            .navigationTitle("Apple Stoer")
        }
    }
}

struct ToolBarHeaderScrollEffectDetailView: View {
    @State private var isHeaderChanged: Bool = false
    @State private var isDownloaded: Bool = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(.sloth)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(.rect(cornerRadius: 25))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mockview")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("Graphic & Design")
                            .font(.callout)
                            .foregroundStyle(.gray)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)

                Image(.IMG_0204)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 850)
            }
        }
        .appStoreStyleToolBar(
            triggerOffset: 110,
            beforeTrailingContent: {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.medium)
                }
                .buttonStyle(ToolbarButtonStyleiOS26())
            },
            afterTrailingContent: {
                ZStack(alignment: .trailing) {
                    Button {
                        isDownloaded.toggle()
                    } label: {
                        Image(systemName: "icloud.and.arrow.down")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(ToolbarButtonStyleiOS26())
                    .opacity(isDownloaded ? 0 : 1)

                    Button {
                        isDownloaded.toggle()
                    } label: {
                        Text("Open")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .fixedSize()
                            .frame(width: isDownloaded ? nil : 0)
                    }
                    .buttonStyle(ToolbarButtonStyleiOS26(isTinted: true))
                    .opacity(isDownloaded ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.15), value: isDownloaded)
            },
            beforeCenterContent: {},
            afterCenterContent: {
                Image(.sloth)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .clipShape(.rect(cornerRadius: 10))

            }, onStatusChanged: { isChanged in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isHeaderChanged = isChanged
                }
            }
        )
    }
}

#Preview {
    ToolBarHeaderScrollEffectDemoView()
}
