//
//  ExpandableMenuiOS26DemoView.swift
//  animation
//
//  Created on 12/18/25.
// Apple book style expandable menu buttons

import SwiftUI

struct ExpandableMenuiOS26DemoView: View {
    @State private var isPresented: Bool = false
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("iPhone Guide") {}

                NavigationLink("iPad Guide") {}
            }
            .navigationTitle("Apple Books")
        }
        .overlay {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(.primary.opacity(isPresented ? 0.2 : 0))
                    .allowsHitTesting(isPresented)
                    .onTapGesture {
                        isPresented = false
                    }
                    .animation(animation, value: isPresented)
                    .ignoresSafeArea()

                MiniatureMenuAction(animation: animation, isPresented: $isPresented) {
                    actionContent()
                } background: {
                    ZStack {
                        Capsule()
                            .fill(.background)
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    .shadow(color: .gray.opacity(0.5), radius: 1)
                }
                .padding(.trailing, 15)
                .padding(.bottom, 10)
            }
        }
    }

    func actionContent() -> some View {
        VStack(spacing: 10) {
            CustomMenuButton(title: "Search Book", symbol: "magnifyingglass", isPresented: $isPresented)
                .frame(width: 250, height: 45)
            CustomMenuButton(title: "Theme & Settings", symbol: "textformat.size", isPresented: $isPresented)
                .frame(width: 250, height: 45)

            HStack(spacing: 10) {
                CustomMenuSectionButton(symbol: "square.and.arrow.up", isPresented: $isPresented)
                CustomMenuSectionButton(symbol: "lock.rotation", isPresented: $isPresented)
                CustomMenuSectionButton(symbol: "pawprint", isPresented: $isPresented)
                CustomMenuSectionButton(symbol: "bookmark", isPresented: $isPresented)
            }
            .font(.title3)
            .fontWeight(.medium)
            .frame(width: 250, height: 50)
        }
        .foregroundStyle(.primary)
    }

    var animation: Animation {
        .smooth(duration: 0.5, extraBounce: 0)
    }
}

struct MiniatureMenuAction<Actions: View, Background: View>: View {
    var innerScaling: CGFloat = 1.0
    var minimizedButtonSize: CGSize = .init(width: 50, height: 50)
    var animation: Animation
    @Binding var isPresented: Bool
    @ViewBuilder var actions: Actions
    @ViewBuilder var background: Background

    var body: some View {
        actions
            .allowsHitTesting(isPresented)
            .contentShape(.rect)
            .compositingGroup()
            /// Using visual effect modifier to scaling actions to fit the button size
            .visualEffect { [innerScaling, minimizedButtonSize, isPresented] content, proxy in
                let maxValue = max(proxy.size.width, proxy.size.height)
                let minButtonValue = min(minimizedButtonSize.width, minimizedButtonSize.height)
                let fitScale = minButtonValue / maxValue
                let modifiedInnerScale = 0.55 * innerScaling // this is to scale content
                return content
                    .scaleEffect(isPresented ? 1 : modifiedInnerScale)
                    .scaleEffect(isPresented ? 1 : fitScale)
            }
            /// create button tap effect
            .overlay {
                if !isPresented {
                    Capsule()
                        .foregroundStyle(.clear)
                        .frame(width: minimizedButtonSize.width, height: minimizedButtonSize.height)
                        .contentShape(.capsule)
                        .onTapGesture {
                            isPresented = true
                        }
                        .transition(.identity)
                }
            }
            .background {
                background
                    .frame(
                        width: isPresented ? nil : minimizedButtonSize.width,
                        height: isPresented ? nil : minimizedButtonSize.height
                    )
                    .compositingGroup()
                    /// create fading out with blur effect
                    .opacity(isPresented ? 0 : 1)
                    .blur(radius: isPresented ? 30 : 0)
            }
            .fixedSize()
            .frame(
                width: isPresented ? nil : minimizedButtonSize.width,
                height: isPresented ? nil : minimizedButtonSize.height
            )
            .animation(animation, value: isPresented)
    }
}

private struct CustomMenuButton: View {
    var title: String
    var symbol: String
    var action: () -> Void = {}
    @Binding var isPresented: Bool
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer(minLength: 0)
                Image(systemName: symbol)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isPresented ? 1 : 0)
            .background {
                ZStack {
                    Rectangle()
                        .fill(.primary)
                        .opacity(isPresented ? 0 : 1)
                    Rectangle()
                        .fill(.background)
                        .opacity(isPresented ? 1 : 0)
                }
                .clipShape(.capsule)
            }
        }
    }
}

private struct CustomMenuSectionButton: View {
    var symbol: String
    @Binding var isPresented: Bool

    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: .infinity, height: .infinity)
                .opacity(isPresented ? 1 : 0)
                .background {
                    ZStack {
                        Rectangle()
                            .fill(.primary)
                            .opacity(isPresented ? 0 : 1)
                        Rectangle()
                            .fill(.background)
                            .opacity(isPresented ? 1 : 0)
                    }
                    .clipShape(.capsule)
                }
        }
    }
}

#Preview {
    ExpandableMenuiOS26DemoView()
}
