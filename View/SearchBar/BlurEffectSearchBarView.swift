//
//  BlurEffectSearchBarView.swift
//  animation
//
//  1. make header sticky
//  2. make header fade away when scrollView scrolled
//  2.1: view scroll faster at the beginning b.c. header height changes dynamically ->
// to solve this, push the view in the opposite direction w/ the amount of height reduced, 75 CGFloat
//  3. implement expandable search bar
//

import SwiftUI

struct BlurEffectSearchBarDemoView: View {
    var body: some View {
        BlurEffectSearchBarView()
    }
}
struct BlurEffectSearchBarView: View {
    /// View Properties
    @State private var searchText: String = ""
    @State private var progress: CGFloat = 0
    @FocusState private var isFocused: Bool //TODO: 7:11

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(firstSetCards) { item in
                    CardView(item)
                }
            }
            .padding(15)
            .offset(y: isFocused ? 0 : progress * 75) // address 2.1
            .padding(.bottom, 75) // address 2.1
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: isFocused)
            .safeAreaInset(edge: .top, spacing: 0) {
                ResizableHeader()
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(CustomScrollTarget())
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.y + $0.contentInsets.top
        } action: { oldValue, newValue in
            /// ResizableHeader height 60 + bottom padding 15
            progress = max(min(newValue / 75, 1), 0)
        }
    }

    @ViewBuilder
    func ResizableHeader() -> some View {
        let progress = isFocused ? 1 : progress
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.callout)
                        .foregroundStyle(.gray)

                    Text("Nanachi")
                        .font(.title.bold())
                }

                Spacer(minLength: 0)

                /// Profile Button
                Button {

                } label: {
                    Image("fox")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                }
            }
            .frame(height: 60 - (60 * progress), alignment: .bottom)
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 15 - (15 * progress))
            .opacity(1 - progress)
            .offset(y: -10 * progress)

            /// Floating Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")

                TextField("Search Photo", text: $searchText)
                    .focused($isFocused)

                /// Microphone Button
                Button {

                } label: {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(Color.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: isFocused ? 0 : 30)
                    .fill(.background
                        .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y:5))
                        .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y:-5))
                    )
                    .padding(
                        .top, isFocused ? -100 : 0
                    ) // roughly to let background fill the top space + safe areas
            }
            .padding(.horizontal, isFocused ? 0 : 15)
            .padding(.bottom, 10)
            .padding(.top, 5)
        }
        .background {
            ProgressiveBlurView()
                .blur(radius: isFocused ? 0 : 10)
                .padding(.horizontal, -15)
                .padding(.bottom, -10)
                .padding(.top, -100)
        }
        .visualEffect { content, proxy in
            content
                .offset(y: offsetY(proxy))
        }
    }

    private func offsetY(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return minY > 0 ? (isFocused ? -minY : 0) : -minY
    }

    @ViewBuilder
    func CardView(_ item: Card) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader {
                let size = $0.size

                Image(item.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 20))
            }
            .frame(height: 220)

            Text("By: \(item.title)")
                .font(.callout)
                .foregroundStyle(.primary.secondary)
        }
    }
}

struct CustomScrollTarget: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let endPoint = target.rect.minY

        if endPoint < 75 {
            if endPoint > 40 {
                target.rect.origin = .init(x: 0, y: 75)
            } else {
                target.rect.origin = .zero
            }
        }
    }
}

#Preview {
    BlurEffectSearchBarDemoView()
}
