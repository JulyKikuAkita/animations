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

                NavigationLink("Example 2") {}
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
            ignoreSafeAreaTop: false,
            isSticky: isSticky
        ) { progress, _ in
            GeometryReader {
                let height = $0.size.height
                RoundedRectangle(cornerRadius: 30)
                    .fill(.indigo.gradient)
                    .overlay {
                        Text("progress: \(progress) - height: \(height)")
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 10)
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
//    @State private var previousDragOffset: CGFloat = 0
//    @State private var headerOffset: CGFloat = 0
//    @State private var headerSize: CGFloat = 0
//    @State private var scrollOffset: CGFloat = 0

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

//    private func combinedHeaderView() -> some View {
//        VStack(spacing: spacing) {
//            header
//                .onGeometryChange(for: CGFloat.self) {
//                    $0.size.height
//                } action: { newValue in
//                    /// spacing is optional
//                    headerSize = newValue + spacing
//                }
//
//            stickyHeader
//        }
//        .offset(y: -headerOffset)
//        .clipped()
//        .background {
//            headerBackground
//                .ignoresSafeArea()
//                .offset(y: -headerOffset)
//        }
}

#Preview {
    ResizableHeaderScrollViewDemo()
}
