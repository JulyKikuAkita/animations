//
//  ResizableHeaderScrollView.swift
//  animation
// iOS 18 API: scroll View and Gesture can work seamlessly
// prior to iOS 18: only either one works
//
import SwiftUI

struct ResizableHeaderScrollViewiOS26Demo: View {
    @Namespace private var animation
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Example 1") {
                    Example1View()
                }

                NavigationLink("Example 2") {
                    Example2View()
                        .navigationBarBackButtonHidden()
                }
            }
            .navigationTitle("Resizable Header")
        }
    }
}

struct Example1View: View {
    @State private var isSticky: Bool = false
    var body: some View {
        ResizableHeaderScrolliOS26View(
            minimumHeight: 100,
            maximumHeight: 250,
            ignoreSafeAreaTop: true,
            isSticky: isSticky
        ) {
            progress,
                _ in
            GeometryReader {
                let height = $0.size.height
                RoundedRectangle(cornerRadius: 30)
                    .fill(.orange.gradient)
                    .overlay {
                        Text("""
                            progress: \(progress)
                            height: \(height - safeArea.top)
                            """
                        )
                        .foregroundStyle(.white)
                    }
//                    .padding(.horizontal, 15)
//                    .padding(.top, 10)
            }

        } content: {
            VStack(spacing: 12) {
                Toggle("Sticky Header", isOn: $isSticky)
                    .padding(15)
                    .background(.gray.opacity(0.2), in: .rect(cornerRadius: 15))
                DummyRectangles(color: .yellow, count: 2)
            }
            .padding(15)
        }
    }
}

/// Xbox style header
struct Example2View: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ResizableHeaderScrolliOS26View(
            minimumHeight: 100,
            maximumHeight: 250,
            ignoreSafeAreaTop: false,
            isSticky: false
        ) { progress, _ in
            headerView(progress: progress)
        } content: {
            VStack(spacing: 15) {
                VStack(spacing: 10) {
                    Button {} label: {
                        VStack(spacing: 6) {
                            Text("Install to +")
                                .foregroundStyle(.white)
                            Text("Xbox Series X | S")
                                .font(.caption)
                                .foregroundStyle(.white.secondary)
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(UIColor.systemGreen), in: .rect(cornerRadius: 10))
                    }

                    HStack(spacing: 10) {
                        Button {} label: {
                            VStack(spacing: 6) {
                                Text("Buy")
                                    .foregroundStyle(.white)
                                Text("29.99")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(.gray.opacity(0.2), in: .rect(cornerRadius: 10))
                        }

                        Button {} label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                                .frame(width: 80, height: 60)
                                .background(.gray.opacity(0.2), in: .rect(cornerRadius: 10))
                        }
                    }
                }
                DummyGridView(rowCount: 2, gridCount: 10, tint: .indigo)
            }
            .padding(15)
        }
        .preferredColorScheme(.dark)
    }

    func headerView(progress: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(width: 35, height: 35)
                    .background(.bar, in: .rect(cornerRadius: 10))
            }
            .offset(y: 15 * progress)

            HStack(spacing: 12) {
                let size: CGFloat = 120 - (progress * 80)
                Image(.fox)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    Text("The Fox")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Lorem ipsum dolor sit amet")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
                .compositingGroup()
                .scaleEffect(1 - (0.2 * progress), anchor: .leading)
            }
            .offset(x: 45 * progress)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .bottomLeading
        )
        .background {
            /// late opacity effect
            let opacity = (progress - 0.7) / 0.3
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(opacity)
        }
    }
}

struct ResizableHeaderScrolliOS26View<Header: View,
    Content: View>: View
{
    var minimumHeight: CGFloat
    var maximumHeight: CGFloat
    var ignoreSafeAreaTop: Bool = false
    var isSticky: Bool = false
    /// Resize Progress, SafeArea values
    @ViewBuilder var header: (CGFloat, EdgeInsets) -> Header
    @ViewBuilder var content: Content

    /// View Properties
    @State private var offsetY: CGFloat = 0

    var body: some View {
        GeometryReader {
            let safeArea = ignoreSafeAreaTop ? $0.safeAreaInsets : .init()

            ScrollView(.vertical) {
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    Section {
                        content
                    } header: {
                        GeometryReader { _ in
                            let progress: CGFloat = min(max(
                                offsetY / (maximumHeight - minimumHeight), 0
                            ), 1)
                            let resizedHeight = (maximumHeight + safeArea.top) - (
                                maximumHeight - minimumHeight) * progress
                            /// using safeEdgeInset give more control on UI than padding
                            header(progress, safeArea)
                                .frame(height: resizedHeight, alignment: .bottom)
                                .offset(y: isSticky ? (offsetY < 0 ? offsetY : 0) : 0)
                        }
                        .frame(height: maximumHeight + safeArea.top)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: ignoreSafeAreaTop ? [.top] : [])
            /// Offset is needed to calculate the progress value
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                offsetY = newValue
            }
        }
    }
}

#Preview {
    ResizableHeaderScrollViewiOS26Demo()
}
