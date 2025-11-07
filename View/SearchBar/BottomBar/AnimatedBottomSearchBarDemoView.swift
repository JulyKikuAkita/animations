//
//  AnimatedBottomSearchBarDemoView.swift
//  animation
//
//  Created on 11/7/25.
// Using AnyLayout
// mimic Perplexity Animated Bottom Bar style

import SwiftUI

struct BlinkingBottomBarDemo: App {
    var body: some Scene {
        WindowGroup {
            AnimatedBottomSearchBarDemoView()
        }
    }
}

struct AnimatedBottomSearchBarDemoView: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    let fillColor = Color.gray.opacity(0.15)

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            AnimatedBottomBar(
                hint: "Type anything!",
                text: $text,
                isFocused: $isFocused
            ) {
                buttonPlaceholder("plus")
                    .fontWeight(.medium)
                buttonPlaceholder("magnifyingglass")
                buttonPlaceholder("mic.fill")

            } trailingActions: {
                ZStack {
                    buttonPlaceholder("checkmark")
                        .fontWeight(.medium)
                        .background(.yellow.gradient, in: .circle)
                        .blur(radius: isFocused ? 0 : 5)
                        .opacity(isFocused ? 1 : 0)

                    buttonPlaceholder("mic.fill")
                        .blur(radius: isFocused ? 5 : 0)
                        .opacity(isFocused ? 0 : 1)
                }

            } mainActions: {
                buttonPlaceholder("paperplane.fill")
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    func buttonPlaceholder(_ imageName: String) -> some View {
        Button {
            if imageName == "checkmark", isFocused {
                /// return from textfield
                isFocused = false
            }
        } label: {
            Image(systemName: imageName)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(fillColor, in: .circle)
        }
    }
}

private enum Constants {
    static let lineLimit: Int = 5
    static let iconSize: CGFloat = 35
}

struct AnimatedBottomBar<LeadingAction: View, TrailingAction: View, MainAction: View>: View {
    var highlightWhenEmpty: Bool = true
    var hint: String
    var tint: Color = .yellow
    @Binding var text: String
    /// helpful to convert keyboard behavior of the textfield
    @FocusState.Binding var isFocused: Bool
    @ViewBuilder var leadingActions: () -> LeadingAction
    @ViewBuilder var trailingActions: () -> TrailingAction
    @ViewBuilder var mainActions: () -> MainAction

    /// View Properties
    @State private var isHighlighted: Bool = false

    // ios26+ keyboard show up faster than previous versions
    var animationDuration: CGFloat {
        if isiOS26OrLater {
            0.22
        } else {
            0.33
        }
    }

    var body: some View {
        let mainLayout = isFocused ? AnyLayout(ZStackLayout(alignment: .bottomTrailing)) :
            AnyLayout(HStackLayout(alignment: .bottom, spacing: 10))
        let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
        ZStack {
            mainLayout {
                let subLayout = isFocused ? AnyLayout(VStackLayout(alignment: .trailing, spacing: 20))
                    : AnyLayout(ZStackLayout(alignment: .trailing))
                subLayout {
                    TextField(hint, text: $text, axis: .vertical)
                        .lineLimit(isFocused ? Constants.lineLimit : 1)
                        .focused(_isFocused)
                        .mask {
                            Rectangle()
                                .padding(.trailing, isFocused ? 0 : 40)
                        }

                    /// Leading & Trailing Action View
                    HStack(spacing: 10) {
                        /// leading
                        HStack(spacing: 10) {
                            ForEach(subviews: leadingActions()) { subview in
                                subview
                                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                                    .contentShape(.rect)
                            }
                        }
                        .compositingGroup()
                        /// disable/hide  buttons interaction when not focused
                        .allowsHitTesting(isFocused)
                        .blur(radius: isFocused ? 0 : 6)
                        .opacity(isFocused ? 1 : 0)

                        Spacer(minLength: 0)

                        /// trailing, one icon
                        trailingActions()
                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                            .contentShape(.rect)
                    }
                }
                .frame(height: isFocused ? nil : 55)
                .padding(.leading, 15)
                .padding(.trailing, isFocused ? 15 : 10)
                .padding(.bottom, isFocused ? 10 : 0)
                .padding(.top, isFocused ? 20 : 0)
                .background {
                    ZStack {
                        highlightedBackgroundView()
                        shape
                            .fill(.bar)
                            /// shadow creates huge visual difference
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: -5)
                    }
                }

                /// only one button for main action
                mainActions()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .background {
                        Circle()
                            .fill(.bar)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: -5)
                    }
                    /// when typing, expand the textfield and move main button to the right
                    .visualEffect { [isFocused] content, proxy in
                        content
                            .offset(x: isFocused ? (proxy.size.width + 30) : 0)
                    }
            }
        }
        .geometryGroup()
        .animation(.easeInOut(duration: animationDuration), value: isFocused)
    }

    /// provide neo effect
    private func highlightedBackgroundView() -> some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
            if !isFocused, text.isEmpty, highlightWhenEmpty {
                shape
                    .stroke(
                        tint.gradient,
                        style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .mask {
                        let clearColors: [Color] = Array(repeating: .clear, count: 4)
                        shape
                            .fill(AngularGradient(
                                colors: clearColors + [Color.white] + clearColors,
                                center: .center,
                                angle: .init(degrees: isHighlighted ? 360 : 0)
                            ))
                    }
                    .padding(-2)
                    .blur(radius: 2)
                    .onAppear {
                        /// infinite loop effect
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            isHighlighted = true
                        }
                    }
                    .onDisappear {
                        /// stop highlight animation
                        isHighlighted = false
                    }
                    .transition(.blurReplace)
            }
        }
    }
}

#Preview {
    AnimatedBottomSearchBarDemoView()
}
