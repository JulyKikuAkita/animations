//
//  PhotoAppIOS18View.swift
//  demoApp

import SwiftUI

struct PhotoAppIOS18DemoView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            PhotoAppIOS18View(size: size, safeArea: safeArea)
                .ignoresSafeArea(.all, edges: .top)
        }
    }
}

struct PhotoAppIOS18View: View {
    var size: CGSize
    var safeArea: EdgeInsets
    var sharedData = SharedData()
    var body: some View {
        let minimizedHeight = (size.height + safeArea.top + safeArea.bottom) * 0.4
        let mainOffset = sharedData.mainOffset

        ScrollView(.vertical) {
            VStack(spacing: 10) {
                /// Photo Grid Scroll View
                PhotosScrollView(size: size, safeArea: safeArea)

                /// bottom half view
                OtherContents()
                    .padding(.top, -30)
                    .offset(y: sharedData.progress * 30)
            }
            /// have scrollView is bounce from the top direction
            .offset(y: sharedData.canPullDown ? 0 : mainOffset < 0 ? -mainOffset : 0)
            .offset(y: mainOffset < 0 ? mainOffset : 0)
        }
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentOffset.y
        }, action: { _, newValue in
            sharedData.mainOffset = newValue
        })
        /// disabling the main scrollview interaction when photo grid is expanded
        .scrollDisabled(sharedData.isExpanded)
        .environment(sharedData)
        .gesture(
            /// only allow gesture when the photos grid scrollView is visible
            PhotoAppCustomGesture(isEnabled: sharedData.activePage == 1) { gesture in
                let state = gesture.state
                let translation = gesture.translation(in: gesture.view).y
                let isScrolling = state == .began || state == .changed

                if state == .began {
                    sharedData.canPullDown = translation > 0 && sharedData.mainOffset == 0
                    sharedData.canPullUp = translation < 0 && sharedData.photoScrollOffset == 0
                }

                if isScrolling {
                    /// similar to onChanged modifier in Drag gesture
                    if sharedData.canPullDown, !sharedData.isExpanded {
                        let progress = max(min(translation / minimizedHeight, 1), 0)
                        sharedData.progress = progress
                    }

                    if sharedData.canPullUp, sharedData.isExpanded {
                        let progress = max(min(-translation / minimizedHeight, 1), 0)
                        sharedData.progress = 1 - progress
                    }
                } else {
                    /// Like onEnd modifier in drag gesture
                    withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                        if sharedData.canPullDown, !sharedData.isExpanded {
                            if translation > 0 { /// add more criteria as needed to trigger expand
                                sharedData.isExpanded = true
                                sharedData.progress = 1
                            }
                        }

                        if sharedData.canPullUp, sharedData.isExpanded {
                            if translation < 0 { /// add more criteria as needed to trigger expand
                                sharedData.isExpanded = false
                                sharedData.progress = 0
                            }
                        }
                    }
                }
            }
        )
        .onChange(of: sharedData.canPullDown) { _, newValue in
            print(newValue)
        }
        .background(.gray.opacity(0.05))
    }
}

#Preview {
    PhotoAppIOS18DemoView()
}
