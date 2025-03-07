//
//  Navigation+Extension.swift
//  animation

/// Show/ Hide navigation bar
import SwiftUI

/// Custom View modifier
extension View {
    @ViewBuilder
    func hideNavBarOnSwipe(_ isHidden: Bool) -> some View {
        self
            .modifier(NavBarModifier(isHidden: isHidden))
    }
}

private struct NavBarModifier: ViewModifier {
    var isHidden: Bool
    @State private var isNavBarHidden: Bool?
    func body(content: Content) -> some View {
        content
            .onChange(of: isHidden, initial: true, { oldValue, newValue in
                isNavBarHidden = newValue
            })
            .onDisappear(perform: {
                isNavBarHidden = nil // set variable to nil to force view update when appears
            })
            .background {
                NavigationControllerExtractor(isHidden: isNavBarHidden)
            }
    }
}

/// Extracting UINavigationController from SwiftUI View
private struct NavigationControllerExtractor: UIViewRepresentable {
    var isHidden: Bool?
    func makeUIView(context: Context) -> some UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            /// extract the associated root UIViewController from the UIView. which will hold a UINavigationController
            if let hostView = uiView.superview?.superview,
               let parentController = hostView.parentController {
                if let isHidden {
                    parentController.navigationController?.hidesBarsOnSwipe = isHidden
                }
            }
        }
    }
}

private extension UIView {
    var parentController: UIViewController? {
        sequence(first: self) { view in
            view
                .next
        }
        .first { responder in
            return responder is UIViewController
        } as? UIViewController
    }
}

struct Navigation_Extension: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ContentView()
}
