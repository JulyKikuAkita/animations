//
//  CustomButton.swift
//  animation

import SwiftUI

struct DemoButtonView: View {
    var body: some View {
        CustomButton(buttonTint: .gray) {
            HStack(spacing: 10) {
                Text("Shiba")
                Image(systemName: "chevron.right")
            }
            .fontWeight(.bold)
            .foregroundColor(.white)
        } action: {
            try? await Task.sleep(for: .seconds(2))
            return .failed("error")
        }
        .buttonStyle(.opacityLess)
        .preferredColorScheme(.dark)
    }
}

struct CustomButton<ButtonContent: View>: View {
    var buttonTint: Color = .gray
    var content: () -> ButtonContent
    /// Button Action
    var action: () async -> TaskStatus
    /// View Properties
    @State private var isLoading: Bool = false
    @State private var isFailed: Bool = false
    @State private var taskStatus: TaskStatus = .idle

    /// Popup Properties
    @State private var showPopup: Bool = false
    @State private var popMessage: String = ""
    @State private var wiggle: Bool = false

    var body: some View {
        Button(action: {
            Task {
                isLoading = true
                let taskStatus = await action()
                switch taskStatus {
                case .idle:
                    isFailed = false
                case let .failed(message):
                    isFailed = true
                    popMessage = message
                case .success:
                    isFailed = false
                }
                self.taskStatus = taskStatus
                if isFailed {
                    try? await Task.sleep(for: .seconds(0))
                    wiggle.toggle() // workarond for wiggle effect
                }
                try? await Task.sleep(for: .seconds(0.8))
                if isFailed {
                    showPopup = true
                }
                self.taskStatus = .idle
                isLoading = false
            }
        }, label: {
            content()
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .opacity(isLoading ? 0 : 1)
                .lineLimit(1)
//                .frame(width: isLoading ? 50 : nil, height: isLoading ? 50 : nil) // this is older style, replace with below
//                .background(buttonTint.shadow(.drop(color: .black.opacity(0.15), radius: 6)), in: .capsule)
                .background {
                    GeometryReader {
                        let size = $0.size
                        let circleRadius = 50.0

                        Capsule()
                            .fill(Color(taskStatus == .idle ? buttonTint : taskStatus == .success ? .green : .red).shadow(.drop(color: .black.opacity(0.15), radius: 6)))
                            .frame(width: isLoading ? circleRadius : nil, height: isLoading ? circleRadius : nil)
                            .frame(width: size.width, height: size.height, alignment: .center)
                    }
                }
                .overlay {
                    if isLoading {
                        ProgressView()
                    }
                }
                .overlay {
                    if !isLoading, taskStatus != .idle {
                        Image(systemName: isFailed ? "exclamationmark" : " checkmark")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .wiggle(wiggle)
        })
        .disabled(isLoading)
        .popover(isPresented: $showPopup, content: {
            Text(popMessage)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 10)
                .presentationCompactAdaptation(.popover)
        })
        .animation(.snappy, value: isLoading)
        .animation(.snappy, value: taskStatus)
    }
}

enum TaskStatus: Equatable {
    case idle
    case failed(String)
    case success
}

/// Custom Opacity less button style
extension ButtonStyle where Self == OpacityLessButtonStyle {
    static var opacityLess: Self {
        Self()
    }
}

struct OpacityLessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// Wiggle Extension
 extension View {
    @ViewBuilder
    func wiggle(_ animate: Bool) -> some View {
        keyframeAnimator(initialValue: CGFloat.zero, trigger: animate) { view, value in
            view
                .offset(x: value)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(0, duration: 0.1)
                CubicKeyframe(-5, duration: 0.1)
                CubicKeyframe(5, duration: 0.1)
                CubicKeyframe(-5, duration: 0.1)
                CubicKeyframe(5, duration: 0.1)
                CubicKeyframe(-5, duration: 0.1)
                CubicKeyframe(5, duration: 0.1)
                CubicKeyframe(0, duration: 0.1)
            }
        }
    }
 }


#Preview {
    DemoButtonView()
}
