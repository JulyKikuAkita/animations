//
//  AnimatedPagingIndicatorsView.swift
//  animation

import SwiftUI

struct PagingIndicatorsDemoView: View {
    var body: some View {
        NavigationStack {
            AnimatedPagingIndicatorsView()
        }
    }
}

// 1:51
struct AnimatedPagingIndicatorsView: View {
    /// View Properties
    @State private var colors: [Color] = [.pink, .purple, .blue, .green]
    @State private var opacityEffect: Bool = false
    @State private var clipEdges: Bool = false
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(colors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: 25)
                            .fill(color.gradient)
                            .padding(.horizontal, 5)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .overlay(alignment: .bottom) {
                    PageIndicatorView(
                        activeTint: .white,
                        inactiveTint: .black.opacity(0.25),
                        opacityEffect: opacityEffect,
                        clipEdges: clipEdges
                    )
                }
            }
            .scrollTargetBehavior(.paging) // comment this out for carousel style
            .scrollIndicators(.hidden)
            .frame(height: 220)
            .padding(15)  // comment this out for carousel style
            /// use below for carousel style
//            .scrollTargetBehavior(.viewAligned)
//            .safeAreaPadding(.vertical, 15)
//            .safeAreaPadding(.horizontal, 25)

            List {
                Section("Options") {
                    Toggle("Opacity Effect", isOn: $opacityEffect)
                    Toggle("Clip Edges", isOn: $clipEdges)

                    Button("Add Card") {
                        colors.append(.brown)
                    }

                }
            }
            .clipShape(.rect(cornerRadius: 15))
            .padding(15)
        }
        .navigationTitle("Custom Indicator")
    }
}

#Preview {
    PagingIndicatorsDemoView()
}
