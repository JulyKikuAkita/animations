//
//  iOS26-tabbarSheet.swift
//  animation
//
//  Created on 6/23/25.

import MapKit
import SwiftUI

#if canImport(FoundationModels)
    public extension View {
        var isiOS26OrLater: Bool {
            if #available(iOS 26, *) {
                true
            } else {
                false
            }
        }
    }

    struct TabbarSheetDemoiOS26: View {
        var body: some View {
            TabbarSheetiOS26()
        }
    }

    struct TabbarSheetiOS26: View {
        @State private var showBottomBar: Bool = true
        var body: some View {
            Map(initialPosition: .region(.applePark))
                .sheet(isPresented: $showBottomBar) {
                    BottomBarView()
                        .presentationDetents(
                            [.height(isiOS26OrLater ? 80 : 130), .fraction(0.6), .large]
                        )
                        .presentationBackgroundInteraction(.enabled)
                }
        }
    }

    struct BottomBarView: View {
        @State private var activeTab: AppleFindMyTab = .devices
        var body: some View {
            GeometryReader {
                let safeArea = $0.safeAreaInsets
                // divide by a larger number, e.g., 5, left less space at the bottom
                let bottomPadding = safeArea.bottom / 2

                VStack(spacing: 0) {
                    /// swtich tab bar
                    /// individualTabView(activeTab)

                    TabView(selection: $activeTab) {
                        Tab(value: .people) {
                            individualTabView(.people)
                        }

                        Tab(value: .devices) {
                            individualTabView(.devices)
                        }

                        Tab(value: .items) {
                            individualTabView(.devices)
                        }

                        Tab(value: .me) {
                            individualTabView(.devices)
                        }
                    }
                    .tabViewStyle(.tabBarOnly)
                    .background {
                        if #available(iOS 26, *) {
                            TabViewHelper()
                        }
                    }
                    /// gorup switUIView -> so we can  extract the souce swiftUI view
                    .compositingGroup()

                    customTabBar()
                        .padding(.bottom, isiOS26OrLater ? bottomPadding : 0)
                }
                .ignoresSafeArea(.all, edges: isiOS26OrLater ? .bottom : [])
            }
            .interactiveDismissDisabled()
        }

        func individualTabView(_ tab: AppleFindMyTab) -> some View {
            ScrollView(.vertical) {
                VStack {
                    HStack {
                        Text(tab.rawValue)
                            .font(isiOS26OrLater ? .largeTitle : .title)
                            .fontWeight(.bold)

                        Spacer(minLength: 0)

                        Group {
                            if #available(iOS 26, *) {
                                Button {} label: {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                            } else {
                                Button {} label: {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .frame(width: 30, height: 30)
                                }
                                .buttonBorderShape(.circle)
                            }
                        }
                    }
                    .padding(.top, isiOS26OrLater ? 15 : 10)
                    .padding(.leading, isiOS26OrLater ? 10 : 0)
                }
                .padding(15)

                /// tab bar connet
                Text(dummyDescription)
            }
            /// ios 26 bug: didn't hide the toolbar
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbarBackgroundVisibility(.hidden, for: .tabBar)
        }

        /// notice iOS26, the bottom safe area changes when sheet w/ different height
        func customTabBar() -> some View {
            HStack(spacing: 0) {
                ForEach(AppleFindMyTab.allCases, id: \.rawValue) { tab in
                    VStack(spacing: 6) {
                        Image(systemName: tab.symbolImage)
                            .font(.title3)
                            .symbolVariant(.fill)

                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(activeTab == tab ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                    .onTapGesture {
                        activeTab = tab
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, isiOS26OrLater ? 12 : 5)
            .overlay(alignment: .top) {
                if !isiOS26OrLater {
                    Divider()
                }
            }
        }
    }

    @available(iOS 26.0, *)
    #Preview {
        TabbarSheetDemoiOS26()
    }

    /// Use UIKit to clear background
    @available(iOS 26.0, *)
    private struct TabViewHelper: UIViewRepresentable {
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.backgroundColor = .clear

            DispatchQueue.main.async {
                guard let compositeGroup = view.superview?.superview else { return }
                guard let swiftUIWrapperUITabView = compositeGroup.subviews.last else { return }

                if let tabBarController = swiftUIWrapperUITabView.subviews.first?.next as? UITabBarController {
                    /// Clearning backtround
                    tabBarController.view.backgroundColor = .clear
                    tabBarController.viewControllers?.forEach {
                        $0.view.backgroundColor = .clear
                    }
                    tabBarController.delegate = context.coordinator
                    /// tmp solution for the glass effect tab bar animatino when switch tab
                    tabBarController.tabBar.removeFromSuperview()
                }
            }

            return view
        }

        func updateUIView(_: UIView, context _: Context) {}

        // starting with iOS18+, the tab view has default fade-in/out transtion when switching tabs,
        // without any background, the result is weired transtioin animation
        // to resolve it we need to replace with a custom identity transtiion animation
        // Also we can use containerBackground view modefider to remove NavigatonStack View background
        // (e.g., navigatonStack has its own bg color)
        class Coordinator: NSObject, UITabBarControllerDelegate, UIViewControllerAnimatedTransitioning {
            func tabBarController(_: UITabBarController,
                                  animationControllerForTransitionFrom _: UIViewController,
                                  to _: UIViewController) ->
                (any UIViewControllerAnimatedTransitioning)?
            {
                self
            }

            func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
                .zero
            }

            func animateTransition(
                using transitionContext: any UIViewControllerContextTransitioning
            ) {
                guard let destinationView = transitionContext.view(forKey: .to) else {
                    return
                }

                let containerView = transitionContext.containerView
                containerView.addSubview(destinationView)
                transitionContext.completeTransition(true)
            }
        }
    }
#endif
