//
//  TextFieldMicroInteractionView.swift
//  animation
//
//  Created on 1/22/26.
//
//  Learning point
//  ──────────────
//  WhatsApp / Telegram-style chat composer with three INTEGRATED
//  micro-interactions:
//    • **Tap-to-send** when message is non-empty → paperplane.
//    • **Press-and-hold-to-record** when message is empty → mic
//      grows + slides; user can drag left to cancel.
//    • **Slide-to-cancel** with a "Slide to cancel" hint shimmer
//      and a trash-can-lid-opens animation on cancellation.
//
//  All three live on the same circular button. The trick: a
//  `LongPressGesture.sequenced(before: DragGesture)` lets the SAME
//  button do all three behaviours based on user intent — quick tap
//  vs hold vs hold-then-drag.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Sequenced gesture for hold-to-record + slide-to-cancel** —
//       `LongPressGesture(minimumDuration: 0.3).sequenced(before: DragGesture)`
//       fires `isHolding` after 300ms of pressing, then `isRecording`
//       once the drag begins. Three `.updating { }` callbacks unpack
//       the gesture state into separate `@GestureState` properties
//       that auto-reset on release.
//    2. **Symbol morphs with `.contentTransition(.symbolEffect(.replace))`** —
//       the central icon swaps `mic.fill → waveform → paperplane.fill`
//       as `isRecording` and `message.isEmpty` change. iOS 17+'s
//       symbol-morph transition handles the visual seamlessly.
//    3. **`.gesture(_:isEnabled:)` to multiplex** — the same view
//       has TWO gesture modifiers: a tap (enabled when message is
//       non-empty) and the long-press+drag (enabled when message
//       is empty). Mutually-exclusive, so only one fires per
//       interaction. Cleaner than a single gesture with branching.
//
//  The mask trick on the message capsule
//  ─────────────────────────────────────
//      .mask {
//          Rectangle()
//              .padding(-50)                              // for shadows
//              .padding(.trailing, abs(recorderOffset))   // shrink right edge
//      }
//
//  As the user drags the recording button left (`recorderOffset`
//  goes negative), the message capsule's RIGHT edge eats inward
//  by the same distance — visually "swallowing" the capsule from
//  the right. Subtle but reads as "you're heading toward cancel."
//
//  The trash-can keyframe on cancel
//  ────────────────────────────────
//  When `disableBottomBar = true` (cancel triggered), the
//  `AnimatedMenuButton` runs a multi-stage `KeyframeAnimator`:
//    1. Mic icon flies UP (-50pt) and ROTATES 360° (0.25s).
//    2. Mic icon shrinks to 0.5x at the original position (0.25s).
//    3. Mic icon fades out (0.1s).
//    4. Meanwhile, the trash icon scales 0.5 → 1 → 1 → 0.5 over
//       0.9s, with the lid opening at the apex.
//  Two parallel `keyframeAnimator(initialValue: KeyFrame())`
//  blocks coordinate this. The custom `KeyFrame` struct uses
//  iOS 26's `@Animatable` macro to interpolate all 4 properties
//  (opacity, scale, offset, rotation) in lockstep.
//
//  Why NOT use `disabled(true)` to gate input during cancel
//  ────────────────────────────────────────────────────────
//  See the comment in the file:
//  `disabled` / `allowsHitTesting` would dismiss the keyboard
//  and visibly break the in-flight animation. The workaround is
//  an invisible Rectangle overlay with `.contentShape(.rect)`
//  that swallows touches without affecting first-responder state.
//
//  Why `@GestureState` (not `@State`) for `isRecording`
//  ────────────────────────────────────────────────────
//  `@GestureState` auto-resets to its initial value when the
//  gesture ends. Using plain `@State` would leave `isRecording`
//  stuck after the user lifted their finger, and we'd have to
//  manually reset in `onEnded`. The auto-reset is essential here
//  for the cleanup branch (`if -lastRecorderOffset > 50 { ... }`)
//  to fire correctly on every release.
//
//  Key APIs
//  ────────
//  • `LongPressGesture.sequenced(before: DragGesture)` — chain
//    gesture phases.
//  • `@GestureState + .updating { }` — auto-resetting transient
//    state inside gestures.
//  • `KeyframeAnimator(initialValue:trigger:)` + `@Animatable` —
//    multi-property keyframed animations.
//  • `.contentTransition(.symbolEffect(.replace, options: .default.speed(1.2)))` —
//    SF Symbol morph with custom speed.
//  • `.scaleEffect(_, anchor:)` — anchor matters for the trash
//    can's lid hinge.
//
//  How to apply
//  ────────────
//  Use this whole file as the reference template for any
//  "context-sensitive primary button" — chat composers, social
//  voice posts, voice search. The sequenced-gesture +
//  multiplexed-tap idea is the architectural lesson.
//
//  See also
//  ────────
//  • SlideToCancelText.swift — companion shimmer hint shown
//    inside the message capsule during recording.
//  • View/Slider/MicroInteractionSlider.swift — sibling pattern
//    for "slide to confirm" with similar gesture choreography.
//
import SwiftUI

struct TextFieldMicroInteractionDemoView: View {
    @State private var message: String = ""
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {}
                .navigationTitle("Demo")
                .safeAreaInset(edge: .bottom) {
                    ChatBottomBar(
                        message: $message
                    ) {} onRecordingStart: {} onRecordingFinished: { discarded in
                        if discarded {
                            print("discard recording")
                        } else {}
                    } addMenu: {}
                        .padding(.horizontal, 15)
                        .padding(.bottom, 5)
                }
        }
    }
}

struct ChatBottomBar: View {
    var hint: String = "Type your message..."
    @Binding var message: String
    var sendMessage: () -> Void
    var onRecordingStart: () -> Void
    var onRecordingFinished: (_ discarded: Bool) -> Void
    var addMenu: () -> Void = {}

    /// Gesture Properties
    @GestureState private var isHolding: Bool = false
    @GestureState private var isRecording: Bool = false
    @GestureState private var recorderOffset: CGFloat = 0
    /// View Properties
    @State private var lastRecorderOffset: CGFloat = 0
    @State private var recordedStartTimeStamp: Date = .now
    @State private var disableBottomBar: Bool = false
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                AnimatedMenuButton(
                    isRecording: isRecording,
                    disableBottomBar: $disableBottomBar,
                    action: addMenu
                )

                TextField(hint, text: $message, axis: .vertical)
                    .lineLimit(5)
                    .opacity(isRecording ? 0 : 1)
                    .overlay {
                        if isRecording {
                            HStack(spacing: 0) {
                                Text(recordedStartTimeStamp, style: .timer)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.gray)

                                Spacer(minLength: 0)

                                SlideToCancelText(text: "Slide to cancel")
                            }
                            .padding(.trailing, 10)
                        }
                    }
                    .animation(.interpolatingSpring(duration: 0.3), value: isRecording)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(.ultraThinMaterial, in: .capsule)
            .mask {
                Rectangle()
                    /// for any shows applied
                    .padding(-50)
                    .padding(.trailing, abs(recorderOffset))
            }
            .shadow(radius: 1)

            Image(systemName: mainActionSymbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace, options: .default.speed(1.2)))
                .frame(width: 48, height: 48)
                .background(.blue.gradient, in: .circle)
                .scaleEffect(isRecording ? 1.3 : 1.0)
                .offset(x: recorderOffset)
                .gesture(sendMessageGesture, isEnabled: !message.isEmpty)
                .gesture(
                    LongPressGesture(minimumDuration: 0.3, maximumDistance: 0)
                        .sequenced(before: DragGesture(minimumDistance: 10))
                        .updating($isHolding, body: { _, out, _ in
                            out = true
                        }).updating($isRecording, body: { value, out, _ in
                            if case .second = value {
                                /// Successfully entered drag gesture after long press
                                out = true
                            }
                        }).updating($recorderOffset, body: { value, out, _ in
                            if case let .second(_, gesture) = value, let gesture {
                                let translation = gesture.translation.width
                                /// Update this according to your own needs
                                let cappedOffset = max(min(translation, 0), -200)
                                out = cappedOffset
                            }
                        }),
                    isEnabled: message.isEmpty
                )
        }
        .animation(.interpolatingSpring(duration: 0.4), value: isHolding)
        .animation(.interactiveSpring(duration: 0.3), value: recorderOffset == 0)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                recordedStartTimeStamp = .now
                onRecordingStart()
            } else {
                /// condition to discard the recording
                if -lastRecorderOffset > 50 {
                    disableBottomBar = true
                    onRecordingFinished(true)
                } else {
                    onRecordingFinished(false)
                }

                lastRecorderOffset = 0
            }
        }
        .onChange(of: recorderOffset) { _, newValue in
            if isRecording {
                lastRecorderOffset = newValue
            }
        }
        .overlay {
            /// do Not use disabled / allowHit Testing here to disable interaction -> it hides the keyboard and mess up animation
            if disableBottomBar {
                Rectangle()
                    .foregroundColor(.clear)
                    .contentShape(.rect)
                    .transition(.identity)
            }
        }
    }

    var mainActionSymbol: String {
        let recordingSymbol: String = isRecording ? "waveform" : "mic.fill"
        return message.isEmpty ? recordingSymbol : "paperplane.fill"
    }

    var sendMessageGesture: some Gesture {
        TapGesture(count: 1).onEnded { _ in
            sendMessage()
        }
    }
}

struct AnimatedMenuButton: View {
    var isRecording: Bool
    /// disable interaction when animation is active
    @Binding var disableBottomBar: Bool
    var action: () -> Void
    /// View Properties
    @State private var isTrashOpen: Bool = false
    @State private var keyframeTrigger: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording || disableBottomBar {
                    Image(systemName: "mic")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                        .keyframeAnimator(initialValue: KeyFrame(), trigger: keyframeTrigger) { content, frame in
                            content
                                .scaleEffect(frame.scale, anchor: .bottom)
                                .rotationEffect(.init(degrees: frame.rotation))
                                .offset(y: frame.offset)
                                .opacity(frame.opacity)
                        } keyframes: { _ in
                            /// Total duration: 0.6s
                            CubicKeyframe(KeyFrame(offset: -50, rotation: 360), duration: 0.25)
                            CubicKeyframe(KeyFrame(scale: 0.5, offset: 0, rotation: 360), duration: 0.25)
                            CubicKeyframe(KeyFrame(opacity: 0, scale: 0.5, offset: 0, rotation: 360), duration: 0.1)
                        }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }

                CustomTrashCanView(isOpen: isTrashOpen)
                    .keyframeAnimator(
                        initialValue: KeyFrame(
                            opacity: 0,
                            scale: 0.5
                        ),
                        trigger: keyframeTrigger
                    ) {
                        content,
                            frame in
                        content
                            .scaleEffect(frame.scale)
                            .opacity(frame.opacity)
                    } keyframes: { _ in
                        /// Total duration: 0.9s
                        CubicKeyframe(KeyFrame(scale: 1), duration: 0.2)
                        CubicKeyframe(KeyFrame(scale: 1), duration: 0.4) // if set 0.3, the menu item got hidden
                        CubicKeyframe(KeyFrame(opacity: 0, scale: 0.5), duration: 0.2)
                    }
            }
            .frame(width: 30)
        }
        .allowsTightening(!isRecording)
        .animation(.easeInOut(duration: 0.3), value: isRecording)
        .animation(.easeInOut(duration: 0.3), value: disableBottomBar)
        .onChange(of: disableBottomBar) { _, newValue in
            if newValue {
                keyframeTrigger.toggle()
                Task { @MainActor in
                    isTrashOpen = true
                    /// await 0.1s
                    try? await Task.sleep(for: .seconds(0.5))
                    isTrashOpen = false
                    try? await Task.sleep(for: .seconds(0.2))
                    disableBottomBar = false
                }
            }
        }
    }

    @Animatable
    struct KeyFrame {
        var opacity: CGFloat = 1
        var scale: CGFloat = 1
        var offset: CGFloat = 0
        var rotation: CGFloat = 0
    }
}

#Preview {
    TextFieldMicroInteractionDemoView()
}
