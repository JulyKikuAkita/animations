//
//  PopOutMenuView.swift
//  animation
//
import SwiftUI

struct PopOutMenuDemoView: View {
    @Namespace private var animation
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left")
                    .font(.title3)

                PopOutView { isExpanded in
                    // Dummy Row
                    HStack {
                        ZStack {
                            if !isExpanded {
                                Image(systemName: "number")
                                    .fontWeight(.semibold)
                                    .matchedGeometryEffect(id: "#", in: animation)
                            }
                        }
                        .frame(width: 20)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                if isExpanded {
                                    Image(systemName: "number")
                                        .fontWeight(.semibold)
                                        .matchedGeometryEffect(id: "#", in: animation)
                                        .scaleEffect(0.8)
                                }

                                Text("general")
                            }
                            .fontWeight(.semibold)

                            Text("36 Members - 4 Online")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        /// image width is 20 | spacing 10 -> totoal 30
                        .offset(x: isExpanded ? -30 : 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 50)

                } content: { _ in
                    VStack(spacing: 12) {
                        customButton("message", title: "Messages")
                        customButton("note.text", title: "Mails")
                        customButton("square.3.stack.3d.top.fill", title: "Files")
                        customButton("folder", title: "Bookmarks")

                        Divider()

                        customButton("text.book.closed", title: "t&s")
                        customButton("gearshape", title: "Settings")
                    }
                }

                Spacer()

                Image(systemName: "airpods.max")
                    .font(.title3)
            }

            Spacer()
        }
        .padding(15)
    }

    func customButton(_ image: String, title: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .frame(width: 25)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
            .foregroundStyle(Color.primary)
        }
    }
}

struct PopOutView<Header: View, Content: View>: View {
    @ViewBuilder var header: (Bool) -> Header
    @ViewBuilder var content: (Bool) -> Content
    /// View Properties
    @State private var sourceRect: CGRect = .zero
    @State private var showFullScreenCover: Bool = false
    @State private var animateView: Bool = false
    @State private var haptics: Bool = false
    var body: some View {
        header(animateView)
            .background(solidBackground(color: .gray, opacity: 0.1))
            .clipShape(.rect(cornerRadius: 10))
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                sourceRect = newValue
            }
            .contentShape(.rect)
            .frame(
                width: animateView ? nil : sourceRect.width,
                height: animateView ? nil : sourceRect.height
            )
            /// hiding this view when full screen cover pops
            .opacity(showFullScreenCover ? 0 : 1)
            .onTapGesture {
                haptics.toggle()
                toggleFullScreenCover()
            }
            .fullScreenCover(isPresented: $showFullScreenCover) {
                PopOutOverlayView(
                    sourceRect: $sourceRect,
                    animateView: $animateView,
                    header: header,
                    content: content
                ) {
                    withAnimation(.easeInOut(duration: 0.25), completionCriteria: .removed) {
                        animateView = false
                    } completion: {
                        toggleFullScreenCover()
                    }
                }
            }
            .sensoryFeedback(.impact, trigger: haptics)
    }

    /// toggle full screen cover without any animation
    private func toggleFullScreenCover() {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            showFullScreenCover.toggle()
        }
    }
}

/// Custom overlay view (implemented with the full screen cover)
/// appear at the top of the window
private struct PopOutOverlayView<Header: View, Content: View>: View {
    @Binding var sourceRect: CGRect
    @Binding var animateView: Bool
    @ViewBuilder var header: (Bool) -> Header
    @ViewBuilder var content: (Bool) -> Content
    var dismissView: () -> Void
    /// View Properties
    @State private var edgeInsets: EdgeInsets = .init()
    @State private var scale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                /// Close button
                if animateView {
                    Button(action: dismissView) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.primary)
                            .contentShape(.rect)
                    }
                }

                header(animateView)
            }

            if animateView {
                content(animateView)
                    .transition(.blurReplace)
            }
        }
        /// taking available space when expanded
        .frame(maxWidth: animateView ? .infinity : nil)
        .padding(animateView ? 15 : 0)
        .background {
            ZStack {
                solidBackground(color: .gray, opacity: 0.1)
                    .opacity(!animateView ? 1 : 0)

                Rectangle()
                    .fill(.background)
                    .opacity(animateView ? 1 : 0)
            }
        }
        .clipShape(.rect(cornerRadius: animateView ? 20 : 10))
        .scaleEffect(scale, anchor: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .offset(
            x: animateView ? 0 : sourceRect.minX,
            y: animateView ? 0 : sourceRect.minY
        )
        .padding(animateView ? 15 : 0)
        .padding(.top, animateView ? edgeInsets.top : 0)
        .ignoresSafeArea()
        .presentationBackground {
            GeometryReader {
                let size = $0.size

                Rectangle()
                    .fill(.black.opacity(animateView ? 0.5 : 0))
                    .onTapGesture {
                        dismissView()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let height = value.translation.height
                                let scale = height / size.height
                                let applyingRatio: CGFloat = 0.1
                                self.scale = 1 + (scale * applyingRatio)
                            }
                            .onEnded { value in
                                let velocityHeight = value.velocity.height / 5
                                let height = value.translation.height + velocityHeight
                                let scale = height / size.height

                                withAnimation(.easeInOut(duration: 0.25)) {
                                    self.scale = 1
                                }

                                if -scale > 0.5 {
                                    dismissView()
                                }
                            }
                    )
            }
        }
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            guard !animateView else { return }
            edgeInsets = newValue
            Task { @MainActor in
                withAnimation((.easeInOut(duration: 0.25))) {
                    animateView = true
                }
            }
        }
    }
}

#Preview {
    PopOutMenuDemoView()
}

extension View {
    func solidBackground(color: Color, opacity: CGFloat) -> some View {
        Rectangle()
            .fill(.background)
            .overlay {
                Rectangle()
                    .fill(color.opacity(opacity))
            }
    }
}
