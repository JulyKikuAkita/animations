//
//  FloatingTabbar.swift
//  animation
//
//  Learning point
//  ──────────────
//  REUSABLE COMPONENT (not a full demo): a floating capsule tab bar
//  whose active pill slides under the selected tab via
//  `matchedGeometryEffect`, with the active tab also revealing its
//  TEXT LABEL inline. Specific tabs (`.apps` / `.chat`) trigger a
//  conditional adjacent button that morphs in via `MorphingSymbolView`
//  with a soft offset/padding animation.
//
//  Key APIs
//  ────────
//  • `matchedGeometryEffect(id: "ACTIVETAB", in: namespace)` — sliding
//    selection background. The `.fill(.clear)` capsule serves as the
//    matched-geometry SOURCE; the colored capsule is rendered separately
//    via `tabLocation` so its frame can outlive the source's view life.
//  • `.onGeometryChange(for: CGRect.self)` in a named coordinate space
//    (`.named("TABBARVIEW")`) — captures the active tab's frame in the
//    tab bar's local space.
//  • `MorphingSymbolView` (project helper) — keyframe-driven SF symbol
//    morph, used for the trailing `person.fill ↔ slider.vertical.3`.
//  • Layered `.shadow(.drop(...))` on `.background` — soft floating
//    look without `.ultraThinMaterial`.
//
//  How to apply
//  ────────────
//  Drop this into a parent view that supplies `$activeTab` and hides
//  the system tab bar (see FloatingTabBarView.swift for the
//  iOS 17/18 hide gymnastics, or FloatingTabBarViewV2.swift for the
//  cleaner generic version).
//
//  See also
//  ────────
//  • FloatingTabBarView.swift — the demo wrapper that USES this
//    component. Includes a UIKit `HideTabBar` workaround for an
//    iOS 17.3/4 glitch.
//  • FloatingTabBarViewV2.swift — a fully generic, protocol-based
//    rewrite of the same idea (PREFERRED for new code).
//

import SwiftUI

struct FloatingTabbar: View {
    var activeForeground: Color = .white
    var activeBackground: Color = .blue
    @Binding var activeTab: TabiOS17
    @Namespace private var animation /// matched geometry effect
    /// View Properties
    @State private var tabLocation: CGRect = .zero
    var body: some View {
        let status = activeTab == .apps || activeTab == .chat

        HStack(spacing: !status ? 0 : 12) {
            HStack(spacing: 0) {
                ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.rawValue)
                                .font(.title3)
                                .frame(width: 30, height: 30)

                            if activeTab == tab {
                                Text(tab.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(
                            activeTab == tab ? activeForeground : .gray
                        )
                        .padding(.vertical, 2)
                        .padding(.leading, 10)
                        .padding(.trailing, 15)
                        .contentShape(.rect)
                        .background {
                            if activeTab == tab {
                                Capsule()
                                    .fill(.clear)
                                    .onGeometryChange(for: CGRect.self, of: {
                                        $0.frame(in: .named("TABBARVIEW"))
                                    }, action: { newValue in
                                        tabLocation = newValue
                                    })
                                    // notice some fade in.out glitch when switch tab
                                    .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(alignment: .leading) {
                Capsule()
                    .fill(activeBackground.gradient)
                    .frame(width: tabLocation.width, height: tabLocation.height)
                    .offset(x: tabLocation.minX)
            }
            .coordinateSpace(.named("TABBARVIEW"))
            .padding(.horizontal, 5)
            .frame(height: 45)
            .background(
                .background
                    .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                    .shadow(.drop(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)),
                in: .capsule
            )
            .zIndex(10)

            Button {
                if activeTab == .apps {
                } else {}
            } label: {
                MorphingSymbolView(
                    symbol: activeTab == .apps ? "person.fill" : "slider.vertical.3",
                    config: .init(
                        font: .title3,
                        frame: .init(width: 42, height: 42),
                        radius: 2,
                        foregroundColor: activeForeground,
                        keyFrameDuration: 0.3,
                        symbolAnimation: .smooth(duration: 0.3, extraBounce: 0)
                    )
                )
                .background(activeBackground.gradient)
                .clipShape(.circle)
            }
            .allowsHitTesting(status)
            .offset(x: status ? 0 : -20)
            .padding(.horizontal, status ? 0 : -42)
        }
        .padding(.bottom, 5)
        .animation(.smooth(duration: 0.3, extraBounce: 0), value: activeTab)
    }
}

#Preview {
    FloatingTabBarDemoView()
}
