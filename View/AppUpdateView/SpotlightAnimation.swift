//
//  SpotlightAnimation.swift
//  animation
//
//  Created on 11/4/26.
import SwiftUI

@available(iOS 27.0, *)
struct SpotlightAnimationDemo: View {
    @State private var showHighlightView: Bool = false
    @State private var group: [Int: Highlight] = [:]
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    TextField("Search", text: .constant(""))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .highlight(
                            order: 1,
                            title: "Search here",
                            description: dummyDescription,
                            maskShape: .capsule,
                            // use inset to enlarge the icon size
                            inset: 10,
                            group: $group
                        )
                }
                Button("Show View") {
                    showHighlightView.toggle()
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "bell")
                    }
                    .highlight(
                        order: 0,
                        title: "Stay Updated",
                        description: dummyDescription,
                        maskShape: .circle,
                        // use inset to enlarge the icon size
                        inset: 0,
                        group: $group
                    )
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "plus")
                    }
                    .highlight(
                        order: 2,
                        title: "New Item",
                        description: dummyDescription,
                        maskShape: .circle,
                        // use inset to enlarge the icon size
                        inset: 0,
                        group: $group
                    )
                }
            }
        }
        .highlightOverlay(isPresented: $showHighlightView, group: $group)
    }
}

struct Highlight: Identifiable {
    var id: Int
    var title: String
    var description: String
    var maskShape: AnyShape
    var inset: CGFloat
    var frame: CGRect
}

@available(iOS 27.0, *)
extension View {
    @ContentBuilder
    func highlight(
        order: Int,
        title: String,
        description: String,
        maskShape: some Shape,
        inset: CGFloat = 10,
        group: Binding<[Int: Highlight]>
    ) -> some View {
        onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: { newValue in
            let highlight = Highlight(
                id: order,
                title: title,
                description: description,
                maskShape: AnyShape(maskShape),
                inset: inset,
                frame: newValue
            )
            group.wrappedValue[order] = highlight
        }
        // remove on view disappear
        .onDisappear {
            group.wrappedValue[order] = nil
        }
    }

    @ContentBuilder
    func highlightOverlay(
        isPresented: Binding<Bool>,
        group: Binding<[Int: Highlight]>
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            HighlightView(isPresented: isPresented, group: group)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .presentationBackground(.clear)
                .navigationTransition(.crossFade)
        }
    }

    fileprivate func inverseMask(
        alignment: Alignment = .center,
        @ContentBuilder content: () -> some View
    ) -> some View {
        mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    content()
                        .blendMode(.destinationOut)
                }
        }
    }
}

@available(iOS 27.0, *)
private struct HighlightView: View {
    @Binding var isPresented: Bool
    @Binding var group: [Int: Highlight]
    /// View Properties
    @State private var currentHighlight: Highlight?
    @State private var containerSize: CGSize = .zero
    var body: some View {
        Rectangle()
            .fill(.black.opacity(0.7))
            .inverseMask(alignment: .topLeading) {
                if let currentHighlight {
                    let frame = currentHighlight.frame
                    let origin = frame.origin
                    let inset = currentHighlight.inset

                    currentHighlight.maskShape
                        .frame(width: frame.width + inset, height: frame.height + inset)
                        .offset(x: origin.x - inset / 2, y: origin.y - inset / 2)
                }
            }
            .overlay(alignment: .topLeading) {
                let frame = currentHighlight?.frame ?? .zero
                let origin = frame.origin
                let inset = currentHighlight?.inset ?? 0
                // using either top or bottom edge
                let edge: Edge = origin.y > (containerSize.height / 2) ? .bottom : .top

                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: frame.width + inset, height: frame.height + inset)
                    .popover(
                        item: $currentHighlight,
                        arrowEdge: edge
                    ) { highlight in
                        popoverView(highlight: highlight)
                            .frame(width: 330)
                            .presentationCompactAdaptation(.popover)
                            .interactiveDismissDisabled()
                    }
                    .offset(x: origin.x - inset / 2, y: origin.y - inset / 2)
            }
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { newValue in
                containerSize = newValue
            }
            .task {
                try? await Task.sleep(for: .seconds(0.25))
                if let highlight = group[0] {
                    withAnimation(.iSpring()) {
                        currentHighlight = highlight
                    }
                } else {
                    isPresented = false
                }
            }
    }

    private func popoverView(highlight: Highlight) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("\(highlight.id + 1) of \(group.count)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(highlight.title)
                    .font(.title3.bold())
                    .lineLimit(1)

                Text(highlight.description)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.bottom, 4)

            HStack {
                Button("Skip") {
                    // close the popup as well
                    isPresented = false
                }
                .tint(.secondary)

                Spacer(minLength: 0)

                let isLast = highlight.id == group.count - 1
                Button {
                    if isLast {
                        isPresented = false
                    } else {
                        withAnimation(.iSpring()) {
                            let nextIndex = min(highlight.id + 1, group.count - 1)
                            currentHighlight = group[nextIndex]
                        }
                    }

                } label: {
                    Text(isLast ? "Finish" : "Next")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
            }
        }
        .padding(20)
    }

    private var initialDelay: Double {
        0.25
    }
}

@available(iOS 27.0, *)
#Preview {
    SpotlightAnimationDemo()
}
