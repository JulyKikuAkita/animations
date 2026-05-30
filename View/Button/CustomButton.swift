//
//  CustomButton.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cleanup
//        Around line 56: `try? await Task.sleep(for: .seconds(0))`
//        is a deliberate yield (lets SwiftUI commit the previous
//        `taskStatus = ...` mutation BEFORE `wiggle.toggle()`
//        triggers the keyframe animation). Replace with the more
//        explicit `await Task.yield()` and add a one-line comment.
//
//  Learning point
//  ──────────────
//  Async-action button that morphs in place: tap → spinner → green
//  checkmark on success / red X on fail / wiggle + popover on
//  failure. No modal, no confirm — the button itself is the entire
//  flow. Demonstrates how to compose iOS 17 `keyframeAnimator` with
//  Swift Concurrency state mutations.
//
//  State machine (`TaskStatus` enum at module scope):
//    .idle → .loading → (.success | .failed(message)) → .idle (after settle)
//
//  Flow per tap:
//    1. `taskStatus = .loading`, isLoading = true → button shrinks
//       to a circle, spinner appears.
//    2. Caller's `task` closure runs; returns `.success` or
//       `.failed(...)`.
//    3. Result drives icon swap (✓ / ✗) via `.snappy` animation.
//    4. If failed: `Task.yield()` (the sleep-zero), then
//       `wiggle.toggle()` triggers the keyframe wiggle, then
//       0.8s later the popover with the failure message.
//    5. Reset to `.idle`, isLoading = false → button morphs back.
//
//  Key APIs
//  ────────
//  • `keyframeAnimator(initialValue:trigger:keyframes:)` — iOS 17.
//    `KeyframeTrack(\.degrees) { CubicKeyframe(...) }` builds the
//    wiggle as a sequence of rotation angles around 0°.
//  • `.popover(isPresented:)` — iOS 16+. The failure message floats
//    above the button without claiming the full screen.
//  • `OpacityLessButtonStyle` — file-private style that suppresses
//    the default press-opacity dim so the morph reads cleanly.
//  • `.animation(.snappy, value:)` — chained per property to control
//    which transitions feel snappy vs. smooth.
//
//  How to apply
//  ────────────
//  Reach for this when an async action is ATOMIC enough that a modal
//  feels heavy — login, save, send. The wiggle is the most-copied
//  bit; the keyframe track is the reusable core.
//
//  See also
//  ────────
//  • SpinnerButton.swift — same async-button idea but multi-stage
//    state (analyzing → processing → completed); compare the two
//    state-machine flavors.
//  • AnimatedConfirmationButtonDemoView.swift — when the action is
//    DESTRUCTIVE and warrants a confirm step instead of inline morph.
//
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
                    wiggle.toggle() // workaround for wiggle effect
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
