//
//  TabbarOverSheetView.swift
//  animation
//  SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15
//  Use AnimationApp2 to test, preview crash with sceneDelegate
import MapKit
import SwiftUI

extension MKCoordinateRegion {
    /// Apple Park Location Coordinates
    static var applePark: MKCoordinateRegion {
        .init(
            center: .init(
                latitude: 37.3346,
                longitude: -122.0090
            ),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    }
}

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
            .tag(Tab_iOS17.photos)
            .hideNaviTabBar()

            NavigationStack {
                /// Mock map location
                Map(initialPosition: .region(.applePark))
            }
            .tag(Tab_iOS17.apps)
            .hideNaviTabBar()

            NavigationStack {
                Text("Chat")
            }
            .tag(Tab_iOS17.chat)
            .hideNaviTabBar()

            NavigationStack {
                Text("Profile")
            }
            .tag(Tab_iOS17.profile)
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
                ForEach(Tab_iOS17.allCases, id: \.rawValue) { tab in
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
