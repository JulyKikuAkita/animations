//
//  ToastView.swift
//  animation
//  iOS 18

import SwiftUI

struct ToastDemoView: View {
    @State private var toasts: [ToastContentView] = []
    var body: some View {
        NavigationStack {
            List {
                Text("Demo view")
            }
            .navigationTitle("Toasts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show") {
                        showToast()
                    }
                }
            }
        }
        .interactiveToasts($toasts)
    }

    func showToast() {
        withAnimation(.bouncy) {
            let toast = ToastContentView { id in
                ToastView(id)
            }
            toasts.append(toast)
        }
    }

    @ViewBuilder
    func ToastView(_ id: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.fill")

            Text("Hello World!")
                .font(.callout)

            Spacer(minLength: 0)

            Button {
                $toasts.delete(id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(Color.primary)
        .padding(.vertical, 12)
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .background {
            Capsule()
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .padding(.horizontal, 15)
    }
}

// iOS18
fileprivate struct ToastViewiOS18: View {
    @Binding var toasts: [ToastContentView]
    /// View Properties
    @State private var isExpanded: Bool = false
    var body: some View {
        ZStack(alignment: .bottom) {
            if isExpanded { /// toast view will switch from zstack to vstack when tapped thus use is_expanded
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isExpanded = false
                    }
            }

            /// AnyLayout will seamlessly update it's layout and items with animations
            let layout = isExpanded ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
            layout {
                ForEach($toasts) { $toast in
                    // reverse index to show stack of cards effect
                    let index = (toasts.count - 1) - (toasts.firstIndex(where: { $0.id == toast.id }) ?? 0)
                    toast.content
                        .offset(x: toast.offsetX)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let xOffset = value.translation.width < 0 ? value.translation.width : 0
                                    toast.offsetX = xOffset
                                }.onEnded { value in
                                    let xOffset = value.translation.width + (
                                        value.velocity
                                            .width / 2)

                                    if -xOffset > 200 {
                                        /// Remove toast
                                        $toasts.delete(toast.id)
                                    } else {
                                        /// Reset toast to it's initial position
                                        withAnimation {
                                            toast.offsetX = 0
                                        }
                                    }
                                }
                        )
                        .visualEffect { [isExpanded] content, proxy in
                            content
                                .scaleEffect(isExpanded ? 1 : scale(index), anchor: .bottom)
                                .offset(y: isExpanded ? 0 : offsetY(index))
                        }
                        .zIndex(toast.isDeleting ? 1000 : 0)
                        .frame(maxWidth: .infinity)
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: 100),
                                removal: .move(edge: .leading)
                            )
                        )
                }
            }
            .onTapGesture {
                isExpanded.toggle()
            }
            .padding(.bottom, 15)
        }
        .animation(.bouncy, value: isExpanded)
        .onChange(of: toasts.isEmpty) { oldValue, newValue in
            if newValue {
                isExpanded = false
            }
        }
    }

    nonisolated func offsetY(_ index: Int) -> CGFloat {
        let offset = min(CGFloat(index) * 15, 30) /// 30 CGFloat is 2 toasts height
        return -offset
    }

    nonisolated func scale(_ index: Int) -> CGFloat {
        let scale = min(CGFloat(index) * 0.1, 1)
        return 1 - scale
    }

}

#Preview {
    ToastDemoView()
}

struct ToastContentView: Identifiable {
    /// id: help to remove toast from view
    private(set) var id: String = UUID().uuidString
    var content: AnyView

    /// View Properties
    var offsetX: CGFloat = 0
    var isDeleting: Bool = false //set zindex to avoid push back to stacj

    init(@ViewBuilder content: @escaping (String) -> some View) {
        self.content = .init(content(id))
    }
}

extension View {
    @ViewBuilder
    func interactiveToasts(_ toasts: Binding<[ToastContentView]>) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastViewiOS18(toasts: toasts)
            }
    }
}

/// use binding to trigger animation effect
extension Binding<[ToastContentView]> {
    func delete(_ id: String) {
        if let toast = first(where: { $0.id == id }) {
            toast.wrappedValue.isDeleting = true
        }
        withAnimation(.bouncy) {
            self.wrappedValue.removeAll(where: { $0.id == id })
        }
    }
}
