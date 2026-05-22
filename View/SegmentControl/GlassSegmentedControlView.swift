//
//  GlassSegmentedControlView.swift
//  animation
//
//  Created on 5/21/26.

import SwiftUI

struct CustomGlassSegmentControlDemoView: View {
    /// View Properties
    @State private var activeIndex: Int = 0
    @State private var tabs: [CustomGlassSegmentControl.Tab] = [
        .init(title: "Portrait"), .init(title: "Photo "), .init(title: "Video"),
        .init(title: "Cinematic"), .init(title: "Panorama"), .init(title: "Dolby Vision"),
    ]
    var body: some View {
        VStack {
            CustomGlassSegmentControl(selection: $activeIndex, tabs: $tabs)

            Text("\(activeIndex)")

            Button("Go to mid") {
                activeIndex = 3
            }
        }
        .padding()
    }
}

struct CustomGlassSegmentControl: View {
    var config: Config = .init()
    @Binding var selection: Int
    @Binding var tabs: [Self.Tab]

    /// View Properties
    @State private var activeIndex: Int?
    @State private var scrollPosition: ScrollPosition = .init()
    var body: some View {
        GeometryReader {
            let containerSize = $0.size
            let activeSize = tabs[activeIndex ?? 0].viewSize

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach($tabs) { $tab in
                        Text(tab.title)
                            .font(.system(size: 18))
                            .padding(.horizontal, config.refractionDepth + 3)
                            .frame(height: containerSize.height)
                            .onGeometryChange(for: CGSize.self) {
                                $0.size
                            } action: { newValue in
                                tab.viewSize = newValue
                            }
                    }
                }
            }
            .scrollIndicators(.hidden)
            /// start & end at the center
            .safeAreaPadding(.horizontal, containerSize.width / 2)
            .scrollTargetBehavior(CustomScrollTarget(tabs: $tabs))
            .scrollPosition($scrollPosition, anchor: .center)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                if let index = tabs.closetSnapPointIndex(newValue), activeIndex != nil {
                    activeIndex = index
                    selection = index
                }
            }
        }
        .frame(height: 50)
        .task {
            if activeIndex == nil {
                let cappedIndex = max(min(selection, tabs.count - 1), 0)
                selection = cappedIndex
                activeIndex = cappedIndex

                scrollPosition.scrollTo(x: tabs.snapPoints[cappedIndex])
            }
        }.onChange(of: selection) { _, newValue in
            if activeIndex != newValue {
                let cappedIndex = max(min(selection, tabs.count - 1), 0)
                scrollPosition.scrollTo(x: tabs.snapPoints[cappedIndex])
            }
        }
    }

    struct Config {
        var tint: Color = .orange
        var refractionAmount: CGFloat = 10
        var refractionDepth: CGFloat = 17
    }

    struct Tab: Identifiable {
        var title: String
        fileprivate var viewSize: CGSize = .zero
        var id: String { title }

        init(title: String) {
            self.title = title
        }
    }
}

private extension [CustomGlassSegmentControl.Tab] {
    var snapPoints: [CGFloat] {
        var snapPoints: [CGFloat] = []
        var xPos: CGFloat = 0
        for tab in self {
            snapPoints.append(xPos + tab.viewSize.width / 2)
            xPos += tab.viewSize.width
        }
        return snapPoints
    }

    func closetSnapPoint(_ offset: CGFloat) -> CGFloat {
        snapPoints.min(by: {
            abs($0 - offset) < abs($1 - offset)
        }) ?? offset
    }

    func closetSnapPointIndex(_ offset: CGFloat) -> Int? {
        if let (index, _) = snapPoints.enumerated().min(by: {
            abs($0.element - offset) < abs($1.element - offset)
        }) {
            return index
        }
        return nil
    }
}

private struct CustomScrollTarget: ScrollTargetBehavior {
    @Binding var tabs: [CustomGlassSegmentControl.Tab]
    func updateTarget(_ target: inout ScrollTarget, context _: TargetContext) {
        let offset = target.rect.origin.x

        target.rect.origin.x = tabs.closetSnapPoint(offset)
    }

    /// Optional: fast deceleration
    @available(iOS 18.4, *)
    func properties(context _: PropertiesContext) -> Properties {
        var properties = Properties()
        properties.limitsScrolls = true
        return properties
    }
}

#Preview {
    CustomGlassSegmentControlDemoView()
}
