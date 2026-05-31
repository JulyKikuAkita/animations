//
//  TabbarOverSheetView.swift
//  animation
//
//  ⚠️  WIRED INTO THE APP: referenced from `animationApp.swift` as
//      `AnimationTabbar`. Don't delete or rename without updating
//      the app entry point and the pbxproj.
//
//  Learning point
//  ──────────────
//  Apple-Maps-style tab bar that ALWAYS SITS ABOVE a presented
//  bottom sheet (not behind it). Achieved by hosting the tab bar in
//  a SECOND UIWindow (set up in `SceneDelegate.addTabBar`, called
//  on appear), so the SwiftUI sheet's window can come and go without
//  occluding the bar. The `.tabSheet` modifier is the wiring layer
//  that drives the sheet's `presentationDetent` from
//  `WindowSharedModelTabbar` (an `@Observable` shared across both
//  windows via environment).
//
//  Why preview crashes with `@Environment(SceneDelegate.self)`:
//    Previews don't construct a full UIApplicationDelegate, so the
//    SceneDelegate isn't injected. The `#Preview` here uses
//    `@UIApplicationDelegateAdaptor(AppDelegate.self)` and provides
//    a fresh `WindowSharedModelTabbar()` to dodge the crash, with
//    the `.onAppear { sceneDelegate.addTabBar(...) }` call commented
//    out. To run the real two-window setup, use the app target.
//
//  Key APIs
//  ────────
//  • `@UIApplicationDelegateAdaptor(AppDelegate.self)` + custom
//    `SceneDelegate` that creates a second `UIWindow` for the tab bar.
//  • `@Observable class WindowSharedModelTabbar` — passed via
//    `.environment(_)`, observed in BOTH windows.
//  • `.tabSheet(initialHeight:sheetCornerRadius:)` (project helper) —
//    presents a sheet whose detent is bound to shared state.
//  • `MapKit.Map(initialPosition: .region(.applePark))` — the primary
//    surface UNDER the sheet.
//
//  How to apply
//  ────────────
//  Reach for this when content has a primary spatial surface (map,
//  camera viewport, video) and tabs must remain reachable while a
//  detent-controlled sheet is active. Don't reach for it for normal
//  app navigation — a regular TabView is simpler and has fewer
//  windowing edge cases.
//
//  See also
//  ────────
//  • iOS26/iOS26+tabbarSheet.swift — the iOS 26 evolution of this
//    pattern using native sheet detents WITHOUT the second-window
//    trick. Same idea, much less ceremony.
//
import MapKit
import SwiftUI

struct TabbarOverSheetView: View {
    // need to use bindable within view not @Binding property
    @Environment(WindowSharedModelTabbar.self) private var windowSharedModel
//     @Environment(SceneDelegate.self) private var sceneDelegate // crash preview

    var body: some View {
        @Bindable var bindableObject = windowSharedModel
        TabView(selection: $bindableObject.activeTab) {
            NavigationStack {
                Text("Photos")
            }
            .tag(TabiOS17.photos)
            .hideNaviTabBar()

            NavigationStack {
                /// Mock map location
                Map(initialPosition: .region(.applePark))
            }
            .tag(TabiOS17.apps)
            .hideNaviTabBar()

            NavigationStack {
                Text("Chat")
            }
            .tag(TabiOS17.chat)
            .hideNaviTabBar()

            NavigationStack {
                Text("Profile")
            }
            .tag(TabiOS17.profile)
            .hideNaviTabBar()
        }
        .tabSheet(initialHeight: 110, sheetCornerRadius: 15) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        if windowSharedModel.activeTab == .apps {
                            deviceRowView("iphone", "Poop Cleaner", "Home")
                            deviceRowView("ipad", "Journal", "Home")
                            deviceRowView("applewatch", "Health", "Home")
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                }
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .toolbar(content: {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(windowSharedModel.activeTab.title)
                            .font(.title3.bold())
                    }

                    if windowSharedModel.activeTab == .apps {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {}, label: {
                                Image(systemName: "plus")
                            })
                        }
                    }
                })
            }
        } // crash preview
//        .onAppear {
//            guard sceneDelegate.tabWindow == nil else { return }
//            sceneDelegate.addTabBar(windowSharedModel)
//        }
    }

    func deviceRowView(_ image: String, _ title: String, _ subTitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: image)
                .font(.title2)
                .padding(12)
                .background(.background, in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.black)

                Text(subTitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("0 km")
                .font(.callout)
        }
    }
}

struct CustomTabBar: View {
    @Environment(WindowSharedModelTabbar.self) private var windowSharedModel
    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                    Button {} label: {
                        VStack {
                            Image(systemName: tab.rawValue)
                                .font(.title2)

                            Text(tab.title)
                                .font(.caption)
                        }
                        .foregroundStyle(
                            windowSharedModel.activeTab == tab ? Color.accentColor
                                : .gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.rect)
                    }
                }
            }
            .frame(height: 55)
        }
        .background(.regularMaterial)
    }
}

#Preview {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    TabbarOverSheetView()
        .environment(WindowSharedModelTabbar())
}
