//
//  GesturesView.swift
//  animation

import SwiftUI

struct GesturesDemoView: View {
    /// Need to remove view and reload to select interactions dynamically
    @State private var effect = InteractionsEffect.verticalSwipe
    @State private var showView: Bool = true

    var pickerValues: [String] = [InteractionsEffect.horizontalSwipe.rawValue,
                                  InteractionsEffect.verticalSwipe.rawValue,
                                  InteractionsEffect.tap.rawValue,
                                  InteractionsEffect.longPress.rawValue,
                                  InteractionsEffect.pinch.rawValue]
    @State var config: PickerConfig = .init(text: InteractionsEffect.pinch.rawValue)

    var body: some View {
        VStack {
            ZStack {
                if showView {
                    Interactions(effect: effect) { size, _, animate in
                        switch effect {
                        case .tap:
                            PressView(animate: animate, scale: 0.95)
                        case .longPress:
                            PressView(animate: animate)
                        case .verticalSwipe:
                            VerticalSwipeView(size: size, animate: animate)
                        case .horizontalSwipe:
                            HorizontalSwipeView(size: size, animate: animate)
                        case .pinch:
                            PressView(animate: animate, scale: 1.3)
                        }
                    }
                }
            }
            .frame(width: 100, height: 400)

            List {
                Button {
                    config.show.toggle()
                } label: {
                    HStack {
                        Text("Gestures")
                            .foregroundStyle(.gray)

                        Spacer(minLength: 0)

                        ExpandableWheelPickerView(config: $config)
                    }
                }
            }
//            Button("Update Gesture") {
//                showView = false
//                Task {
//                    if let updated = InteractionsEffect.mapEffect(text: config.text) {
//                        effect = updated
//                    }
//                    showView = true
//                }
//            }
        }
        .customWheelPicker($config, items: pickerValues)
        .padding()
        .onChange(of: config.text) {
            guard showView else { return }
            showView = false
            Task {
                if let updated = InteractionsEffect.mapEffect(text: config.text) {
                    effect = updated
                }
                showView = true
            }
        }
    }

    @ViewBuilder
    func HorizontalSwipeView(size: CGSize, animate: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
                .frame(width: 80, height: 150)
                .frame(width: size.width, height: size.height)

            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
                .frame(width: 80, height: 150)
                .frame(width: size.width, height: size.height)
        }
        .offset(x: animate ? -(size.width + 10) : 0)
    }

    @ViewBuilder
    func VerticalSwipeView(size: CGSize, animate: Bool) -> some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
                .frame(width: 80, height: 150)
                .frame(width: size.width, height: size.height)

            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
                .frame(width: 80, height: 150)
                .frame(width: size.width, height: size.height)
        }
        .offset(y: animate ? -(size.height + 10) : 0)
    }

    @ViewBuilder
    func PressView(animate: Bool, scale: CGFloat = 0.9) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
                .frame(width: 80, height: 150)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(animate ? scale : 1)
        }
    }
}

struct Interactions<Content: View>: View {
    var effect: InteractionsEffect
    @ViewBuilder var content: (CGSize, Bool, Bool) -> Content
    /// View priorities
    @State private var showTouch: Bool = false
    @State private var animate: Bool = false
    @State private var isStarted: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(Color.primary, style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            .frame(width: 100, height: 200)
            .background {
                GeometryReader {
                    let size = $0.size
                    content(size, showTouch, animate)
                }
                .clipped()
            }
            .overlay(alignment: .top) {
                /// Dynamic Island
                Capsule()
                    .frame(width: 22, height: 7)
                    .offset(y: 7)
            }
            .overlay(alignment: .bottom) {
                /// Home indicator
                Capsule()
                    .frame(width: 32, height: 2)
                    .offset(y: -7)
            }
            .overlay {
                /// Touch View
                let isSwipe = effect == .verticalSwipe || effect == .horizontalSwipe
                let isPinch = effect == .pinch
                let circleSize: CGFloat = effect == .horizontalSwipe ? 18 : 20

                Circle()
                    .fill(.fill)
                    .frame(width: circleSize, height: circleSize)
                    .offset(y: isPinch ? animate ? -40 : 0 : 0)
                    .overlay {
                        if isPinch {
                            Circle()
                                .fill(.fill)
                                .frame(width: circleSize, height: circleSize)
                                .offset(y: animate ? 40 : 0)
                        }
                    }
                    .opacity(showTouch ? 1 : 0)
                    .blur(radius: showTouch ? 0 : 5)
                    .offset(
                        x: effect == .horizontalSwipe ? (animate ? -25 : 25) : 0,
                        y: effect == .verticalSwipe ? (animate ? -50 : 50) : 0
                    )
                    .scaleEffect(isSwipe ? 1 : isPinch ? 0.8 : (animate ? 0.8 : 1.1))
            }
            .onAppear {
                /// Avoid multiple calls when in lazyViews
                guard !isStarted else { return }
                isStarted = true
                /// Looping animate effect
                Task {
                    await animationEffect()
                }
            }
            .onDisappear {
                isStarted = false
            }
    }

    private func animationEffect() async {
        guard isStarted else { return } /// set exit point when view is removed during recursive call
        let isSwipe = effect == .verticalSwipe || effect == .horizontalSwipe
        let isPinch = effect == .pinch
        withAnimation(.easeIn(duration: 0.5)) {
            showTouch = true
        }

        if effect == .tap {
            withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                animate = true
            }
            try? await Task.sleep(for: .seconds(0.2))

        } else {
            withAnimation(.snappy(duration: 1, extraBounce: 0)) {
                animate = true
            }
            try? await Task.sleep(for: .seconds(effect == .longPress ? 1.3 : 1))
        }

        /// Resetting animation
        withAnimation(.easeIn(duration: 0.3), completionCriteria: .logicallyComplete) {
            if isSwipe || isPinch {
                showTouch = false
            } else {
                animate = false
            }
        } completion: {
            if isSwipe {
                animate = false
            }

            /// no reverse effect for pinch interaction
            if isPinch {
                withAnimation(.linear(duration: 0.2)) {
                    animate = false
                }
            }
        }

        /// Looping
        try? await Task.sleep(for: .seconds(effect == .tap ? 0.3 : isPinch ? 1 : 0.6))
        await animationEffect()
    }
}

#Preview {
    GesturesDemoView()
}

enum InteractionsEffect: String {
    case tap
    case longPress
    case verticalSwipe
    case horizontalSwipe
    case pinch

    static func mapEffect(text: String) -> InteractionsEffect? {
        InteractionsEffect(rawValue: text)
    }
}
