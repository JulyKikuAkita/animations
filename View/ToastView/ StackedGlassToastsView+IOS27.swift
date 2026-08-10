//
//   StackedGlassToastsView+IOS27.swift
//  animation
//
//  Created on 8/9/26.

import SwiftUI

@available(iOS 27.0, *)
private struct StackedToastsDemoViews: View {
    @State private var glassTintOpacity: CGFloat = 0.0
    @State private var containerToasts: [StackedToast] = []
    var body: some View {
        NavigationStack {
            List {
                Section("Glass Tint Opacity") {
                    Slider(value: $glassTintOpacity)
                }

                Section("Action") {
                    Button("Add Toast", action: addToast)
                }
            }
            .navigationTitle("Stacked Glass Toasts")
        }
        .overlay(alignment: .bottom) {
            StackedToastsView(
                glassTintOpacity: glassTintOpacity,
                toasts: $containerToasts
            )
        }
    }

    func addToast() {
        let toast = StackedToast(
            symbol: "exclamationmark.triangle.fill",
            title: "Connection Failed",
            description: "Something went wrong. Please try again!",
            tintColor: .red
        )

        containerToasts.append(toast)
    }
}

/// Toast Model
private struct StackedToast: Identifiable, Equatable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var description: String
    var tintColor: Color
    /// Automatic dismiss after the given time(in seconds)
    var autoDismissInterval: Double? = nil
}

@available(iOS 27.0, *)
private struct StackedToastsView: View {
    let singleToastFrameHeight: CGFloat = 65
    let toastContainerHeight: CGFloat = 90

    var glassTintOpacity: CGFloat = 0
    @Binding var toasts: [StackedToast]

    var body: some View {
        /// Using scrollView with visualEffect API to create stack  (not using zStack)
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(toasts.reversed()) { toast in
                    let index = toasts.firstIndex(of: toast) ?? 0

                    SingleToastView(glassTintOpacity: glassTintOpacity, toast: toast) {
                        toasts.removeAll(where: { $0.id == toast.id })
                    }
                    .visualEffect { content, proxy in
                        let minY = proxy.frame(in: .scrollView).minY
                        let progress = minY / singleToastFrameHeight
                        /// only push 2 toasts
                        let offset = min(progress * 10, 20)
                        let scale = min(progress * 0.05, 0.1)

                        return content
                            .scaleEffect(1 - scale, anchor: .bottom)
                            .offset(y: -minY)
                            .offset(y: offset)
                    }
                    .zIndex(Double(index))
                    .transition(.asymmetric(
                        insertion: .offset(y: 500).combined(with: AnyTransition(.blurReplace)),
                        removal: .move(edge: .leading).combined(with: AnyTransition(.blurReplace))
                    )
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .frame(height: toastContainerHeight)
        .offset(y: 25 - max(min(CGFloat(toasts.count - 1) * 12.5, 25), 0))
        .swipeActionsContainer()
        .background { /// add soft blur background using safe area bar
            /// soft area bar proves soft and hard blur scroll effects but this is a custom overlay view,
            ///  we cannot attach a safe area bar directly;
            ///  thus we create dummy scroll view to add safe area bar for the blur effect
            ScrollView(.vertical) {}
                .frame(height: 0)
                .allowsHitTesting(false)
                .safeAreaBar(edge: .bottom, spacing: 0) {
                    Text("").frame(maxWidth: .infinity)
                        .frame(height: toastContainerHeight)
                }
                .scrollEdgeEffectStyle(.soft, for: .bottom)
                .opacity(toasts.isEmpty ? 0 : 1)
        }
        .animation(.smooth(duration: 0.3, extraBounce: 0), value: toasts)
        .allowsHitTesting(!toasts.isEmpty)
    }
}

@available(iOS 27.0, *)
private struct SingleToastView: View {
    let singleToastFrameHeight: CGFloat = 65
    var glassTintOpacity: CGFloat
    var toast: StackedToast
    var onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: toast.symbol)
                .font(.title)
                .foregroundStyle(toast.tintColor.gradient)

            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(toast.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: 310, alignment: .leading)
        .frame(height: singleToastFrameHeight)
        .background {
            let row1 = Array(repeating: toast.tintColor.opacity(0.15), count: 3)
            let row2 = Array(repeating: toast.tintColor.opacity(0.1), count: 3)
            let row3 = Array(repeating: Color.clear, count: 3)

            MeshGradient(
                width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1],
                ],
                colors: row1 + row2 + row3
            )
            .clipShape(.capsule)
        }
        .glassEffect(.regular.tint(glassTint), in: .capsule)
        .contentShape(.capsule)
        .compositingGroup()
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 10)
        /// iOS27+: we can attach swipe action to any view
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            /// note: [bug] on 27 beta, only destructive has full swipe animation
            Button(action: onDismiss) {
                Image(systemName: "checkmark")
            }
            .tint(toast.tintColor)
        }
        .task {
            guard let autoDismissInterval = toast.autoDismissInterval else { return }
            try? await Task.sleep(for: .seconds(autoDismissInterval))
            if !Task.isCancelled { onDismiss() }
        }
    }

    var glassTint: Color {
        (colorScheme == .dark ? Color.black : Color.white).opacity(glassTintOpacity)
    }
}

@available(iOS 27.0, *)
#Preview {
    StackedToastsDemoViews()
}

@available(iOS 27.0, *)
#Preview {
    StackedToastsDemoViews()
        .environment(\.colorScheme, .dark)
}
