//
//  FloatingTabBarView.swift
//  animation

import SwiftUI

//@main
struct FloatingTabBarApp: App {
    var body: some Scene {
        WindowGroup {
            FloatingTabBarDemoView()
        }
    }
}

struct FloatingTabBarDemoView: View {
    /// View Properties
    @State private var activeTab: Tab_iOS17 = .apps
    @State private var isTabBarHidden: Bool = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if #available(iOS 18, *) {
                    TabView(selection: $activeTab) {
                        Tab.init(value: .apps) {
                            FloatingTabBarView()
                                .toolbarVisibility(.hidden, for: .tabBar)
                        }
                        
                        Tab.init(value: .photos) {
                            Text("Photos")
                                .toolbarVisibility(.hidden, for: .tabBar)
                        }
                        
                        Tab.init(value: .chat) {
                            Text("Chat")
                                .toolbarVisibility(.hidden, for: .tabBar)
                        }
                        
                        Tab.init(value: .profile) {
                            Text("Profile")
                                .toolbarVisibility(.hidden, for: .tabBar)
                        }
                    }
                } else { // switch tab bar at iOS17.3/4 has some glitch (https://www.youtube.com/watch?v=JOZv3C1yj7w at 3:15)
                    // Thus need to use UITabbarController to hide the tab bar
                    // Instead of just modifier .toolbar(.hidden, for: .tabBar)
                    TabView(selection: $activeTab) {
                        FloatingTabBarView()
                            .tag(Tab_iOS17.apps)
        //                    .toolbar(.hidden, for: .tabBar) // glitch
                            .background {
                                if !isTabBarHidden {
                                    HideTabBar {
                                        isTabBarHidden = true
                                    }
                                }
                            }
                        
                        Text("Photos")
                            .tag(Tab_iOS17.photos)
//                            .toolbar(.hidden, for: .tabBar)
                        
                        Text("Chat")
                            .tag(Tab_iOS17.chat)
//                            .toolbar(.hidden, for: .tabBar)
                        
                        Text("Profile")
                            .tag(Tab_iOS17.profile)
//                            .toolbar(.hidden, for: .tabBar)
                        
                    }
                }
            }
            
            FloatingTabbar(activeTab: $activeTab)
        }
    }
}
struct FloatingTabBarView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 12) {
                    ForEach(1...50, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background)
                            .frame(height: 50)
                    }
                }
                .padding(15)
            }
            .navigationTitle("Floating Tab bar")
            .background(Color.primary.opacity(0.7))
            .safeAreaPadding(.bottom, 60) /// height for floating tab bar
        }
    }
}

/// Fix iOS17.3/4 has some glitch of  modifier .toolbar(.hidden, for: .tabBar) to hide tab bar
fileprivate struct HideTabBar: UIViewRepresentable {
    init(result: @escaping () -> Void) {
       UITabBar.appearance().isHidden = true
       self.result = result
    }
    
    var result: () -> ()
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let tabController = view.tabController {
                UITabBar.appearance().isHidden = false
                tabController.tabBar.isHidden = true
                result()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

extension UIView {
    var tabController: UITabBarController? {
        if let controller = sequence(first: self, next: {
            $0.next
        }).first(where: { $0 is UITabBarController }) as? UITabBarController {
            return controller
        }
        return nil
    }
}

#Preview {
    FloatingTabBarDemoView()
}