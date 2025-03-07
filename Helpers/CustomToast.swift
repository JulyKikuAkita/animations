//
//  CustomToast.swift
//  animation
// iOS 17

import SwiftUI

/// Root view for creating overlay window
//struct RootView<Content:View>: View {
//    @ViewBuilder var content: Content
//    /// View Properties
//    @State private var overlayWindow: UIWindow?
////    @State private var isFailed: Bool = false
//    var body: some View {
//        content
//            .onAppear {
//                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, overlayWindow == nil {
//                    let window = PassthroughWindow(windowScene: windowScene)
//                    window.backgroundColor = .clear
//                    /// View Controller
//                    let rootController = UIHostingController(rootView: ToastGroup())
//                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
//                    rootController.view.backgroundColor = .clear
//                    window.rootViewController = rootController
//                    window.isHidden = false
//                    window.isUserInteractionEnabled = true
//                    window.tag = 1009 // use the tag view to extract the overlay window from the window scene
//
//                    overlayWindow = window
//                }
//
//            }
//    }
//}

/// pass all the user interaction from overlayWindow down to the root view controller
fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == view ? nil : view
    }
}

/// a signleton object as a state object to receive UI updates on the overlay window root controller
@Observable
class Toast {
    static let shared = Toast()
    fileprivate var toasts: [ToastItem] = []

    func present(title: String, symbol: String?, tint: Color = .primary, isUserInteractionEnabled: Bool = false, timing: ToastTime = .medium) {
        withAnimation(.snappy) {
            toasts.append(.init(title: title, symbol: symbol, tint: tint, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing))
        }
    }
}

struct ToastItem: Identifiable {
    let id: UUID = .init()
    /// Custom Properties
    var title: String
    var symbol: String?
    var tint: Color
    var isUserInteractionEnabled: Bool
    /// Timnig
    var timing: ToastTime = .medium
}

enum ToastTime: CGFloat {
    case short = 1.0
    case medium = 2.0
    case long = 3.0
}

fileprivate struct ToastGroup: View {
    var model = Toast.shared
    let tabbarHeigh: CGFloat = 69

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            ZStack {
//                Text("\(model.toasts.count)")
//                    .offset(y: -100)

                ForEach(model.toasts) { toast in
                    ToastViewiOS17(size: size, item: toast)
                        .scaleEffect(scale(toast))
                        .offset(y: offsetY(toast))
                        .zIndex(Double(model.toasts.firstIndex(where: { $0.id == toast.id }) ?? 0))
                    /// below animation seems not working
//                        .animation(.easeInOut) { view in
//                            view
//                                .offset(y: offsetY(toast))
//                        }
                }
            }
            .padding(.bottom, tabbarHeigh)
            .padding(.bottom, safeArea.top == .zero ? 15: 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// creating a stack feel animation with offsetY and scale
    /// calculating toast stack animation offset, each with offset size 10
    func offsetY(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return (totalCount - index) >= 2 ? -20 : ((totalCount - index) * -10)
    }

    func scale(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat(model.toasts.count) - 1
        return 1.0 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
    }
}

fileprivate struct ToastViewiOS17: View {
    var size: CGSize
    var item: ToastItem

    /// View Properties
    ///  for state style animation
//    @State private var animateIn: Bool = false
//    @State private var animateOut: Bool = false
    @State private var delayTask: DispatchWorkItem?

    var body: some View {
        HStack(spacing: 0) {
            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .padding(.trailing, 10)
            }

            Text(item.title)
                .lineLimit(1)
        }
        .foregroundStyle(item.tint)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            .background
                .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
                .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
            in: .capsule
        )
        .contentShape(.capsule)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded({ value in
                    guard item.isUserInteractionEnabled else { return }
                    let endY = value.translation.height
                    let velocityY = value.translation.height

                    if (endY + velocityY) > 100 {
                        /// swipe gesture to remove toast
                        transitionRemoveToast()
                    }

                })
        )
//        .offset(y: animateIn ? 0 : 150) // use state change for animation; can use transition too
//        .offset(y: !animateOut ? 0 : 150) // only need for state style aniamtion
//        .task {
//            /// only need for state style aniamtion
////            guard !animateIn else { return }
////            withAnimation(.snappy) {
////                animateIn = true
////            }
//
//            try? await Task.sleep(for: .seconds(item.timing.rawValue))
//
//            transitionRemoveToast()
//        }
        .onAppear {
            guard delayTask == nil else { return }
            delayTask = .init(block: {
                removeToastItem()
            })

            if let delayTask {
                DispatchQueue.main.asyncAfter(deadline: .now() + item.timing.rawValue, execute: delayTask)
            }
        }
        /// Limiting size
        .frame(maxWidth: size.width * 0.7)
        .transition(.offset(y: 150))
    }

    /// animation has no delay when item is removed
    func transitionRemoveToast() {
        if let delayTask {
            delayTask.cancel()
        }
        withAnimation(.snappy) {
            Toast.shared.toasts.removeAll(where: { $0.id == item.id })
        }
    }

    /// use state change for animation -> animation has delay when item is removed
//    func removeToast() {
//        guard !animateOut else { return }
//        withAnimation(.snappy, completionCriteria: .logicallyComplete) {
//            animateOut = true
//        } completion: {
//            removeToastItem()
//        }
//    }

    /// use state change for animation
    func removeToastItem() {
        Toast.shared.toasts.removeAll(where: { $0.id == item.id })
    }
}



struct CustomToastView: View {
    var body: some View {
        VStack {
            Button("OK!") {
                Toast.shared.present(
                    title: "Thank you!",
                    symbol: "heart",
                    isUserInteractionEnabled: true
                )
            }
        }
        .padding()
    }
}

#Preview {
    RootView {
        CustomToastView()
    }
}
