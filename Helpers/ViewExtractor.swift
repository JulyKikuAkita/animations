//
//  ViewExtractor.swift
//  animation

import SwiftUI

// extract swiftUI view from UIKit view or vice versa
// Add this to the view we want to tract (not after the modifier otherwise we get result as modifier)
extension View {
    @ViewBuilder
    func ViewExtractor(result: @escaping (UIView) -> ()) -> some View {
        self
            .background(ViewExtractHelper(result: result))
            .compositingGroup()
    }
}

// the view was compose of 2 super views and swiftUI view is at the top of the group, it's the last subview property
// each swiftUI view serves as a wrapper around a UIKit view and the initial view will be a wrapper and within it the associated UIKit View
/// Similar to below hierarchy
///  - grouped view (superView.superView)
///  - extractor view (background)
///  - swiftUI view (subviews.last)
///  - hosting kind a view
///  - UIKit view(subviews.first)  <-- if no UIKit view, this will be null
fileprivate struct ViewExtractHelper: UIViewRepresentable {
    var result: (UIView) -> ()

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            if let uiKitView = view.superview?.superview?.subviews.last?.subviews.first {
                result(uiKitView)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

/// Demo for how to use view extractor
///  UIViewController type - navigation stack, tabview etc, use next property to extract the controllers
struct demoViewExtractorControllerView: View {
    var body: some View {
        NavigationStack {
            List {}
                .navigationTitle("Home")
        }
        .ViewExtractor { view in
            if let navController = view.next as? UINavigationController {
                print(navController)
            }
        }

        TabView {

        }
        .ViewExtractor { view in
            if let tabController = view.next as? UITabBarController {
                tabController.tabBar.isHidden = true
                print(tabController)
            }
        }
    }
}

/// SwiftUi views
struct demoViewExtractorView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)

            /// native SwiftUI view
            Text("Native SwiftUI View which has no UIKit view")
                .ViewExtractor { view in
                        print(view)
                }

            /// UIKit View wrapped with SwiftUI Wrapper: textfield, slider, list etc
            TextField("UIKit View wrapped", text: .constant(""))
                .ViewExtractor { view in
                    if let textField = view as? UITextField {
                        print(textField)
                    }
                }

            Slider(value: .constant(0.2))
                .ViewExtractor { view in
                    if let slider = view as? UISlider {
                        slider.tintColor = .red
                        slider.thumbTintColor = .systemBlue
                        print(slider)
                    }
                }

            HStack {
                List {
                    Text("List in SwiftUI is UICollectionView")
                }
                .ViewExtractor { view in
                    if let list = view as? UICollectionView {
                        print(list)
                    }
                }

                ScrollView {
                    Text("ScrollView in SwiftUI is UIScrollView")
                }
                .ViewExtractor { view in
                    if let scrollView = view as? UIScrollView {
                        scrollView.bounces = false
                        print(scrollView)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    demoViewExtractorView()
}
