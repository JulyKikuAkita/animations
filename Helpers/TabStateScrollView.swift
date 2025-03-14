//
//  TabStateScrollView.swift
//  animation

import SwiftUI

/// Custom View
struct TabStateScrollView<Content: View>: View {
    var axis: Axis.Set
    var showsIndicator: Bool
    @Binding var tabState: Visibility
    var content: Content
    init(axis: Axis.Set, showsIndicator: Bool, tabState: Binding<Visibility>, @ViewBuilder content: @escaping () -> Content) {
        self.axis = axis
        self.showsIndicator = showsIndicator
        _tabState = tabState
        self.content = content()
    }

    var body: some View {
        /// this feature supports iOS 16 and 17
        if #available(iOS 17, *) { // old scroll view deprecated in iOS 17
            ScrollView(axis) {
                content
            }
            .scrollIndicators(showsIndicator ? .visible : .hidden)
            .background {
                CustomGesture {
                    handleTabState($0)
                }
            }
        } else {
            ScrollView(axis, showsIndicators: showsIndicator, content: {
                content
            })
            .background {
                CustomGesture {
                    handleTabState($0)
                }
            }
        }
    }

    /// Handling tab state on swipe
    func handleTabState(_ gesture: UIPanGestureRecognizer) {
//        let offsetY = gesture.translation(in: gesture.view).y
        let velocityY = gesture.velocity(in: gesture.view).y

        if velocityY < 0 {
            /// Swiping up
            if -(velocityY / 5) > 60, tabState == .visible {
                tabState = .hidden
            }
        } else {
            /// Swiping down
            if (velocityY / 5) > 40, tabState == .hidden {
                tabState = .visible
            }
        }
    }
}

/// Adding a custom simultaneous UIPan Gesture to know about  the direction user is swiping
private struct CustomGesture: UIViewRepresentable {
    var onChange: (UIPanGestureRecognizer) -> Void
    /// gesture ID
    private let gestureID = UUID().uuidString

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context _: Context) -> some UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.async {
            // uiview.(background{}).sourceView
            if let superView = uiView.superview?.superview,
               !(superView.gestureRecognizers?.contains(where: { $0.name == gestureID }) ?? false)
            {
                let gesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.gestureChange(gesture:)))
                gesture.name = gestureID // otherwise mutiple gestures will be added
                gesture.delegate = context.coordinator // otherwise gesture won't work
                /// Adding gesture to the super view
                superView.addGestureRecognizer(gesture)
            }
        }
    }

    /// Selector class
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChange: (UIPanGestureRecognizer) -> Void
        init(onChange: @escaping (UIPanGestureRecognizer) -> Void) {
            self.onChange = onChange
        }

        @objc
        func gestureChange(gesture: UIPanGestureRecognizer) {
            /// Simply calling the onChange callback
            onChange(gesture)
        }

        /// enable this for gesture to work simultaneously with other gestures (such as scrollview)
        func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
