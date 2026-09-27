//
//  ChatBubbleTransitionScrollViewEffect.swift
//  animation
//
//  Created on 9/15/26.
//
//  SwiftUI learning notes — key takeaways in this file:
//
//  A message appears to fly out of the compose field and into the chat log, but
//  nothing travels. Two separate views share one `matchedGeometryEffect` id: a
//  throwaway copy of the text drawn as an overlay ON the field, and the real
//  `MessageBubble` in the scroll view. Sending swaps which of the pair exists and
//  SwiftUI interpolates between their frames.
//
//  1. THE SWAP IS DRIVEN BY `currentMessage.id`. The message is appended to
//     `allMessages` *before* the animation, so its bubble is already mounted but
//     empty (`isVisible == false`) while its twin sits over the field. Resetting
//     `currentMessage` flips both conditions in one transaction: the overlay copy
//     leaves, the bubble arrives, matched geometry connects the two frames.
//
//  2. `isFit` IS A TRANSIENT LAYOUT FLAG, NOT DATA. It records whether the typed
//     text stayed on one line, is read at both ends of the transition to choose
//     `matchedGeometryEffect(properties:)`, and is cleared back to `nil` once the
//     animation is torn down — which is why the model declares it `Bool?`.
//
//  3. `@Entry` PUBLISHES THE MEASURED FIELD SIZE to the bubbles. See the note on
//     `EnvironmentValues` below.
//
//  Key APIs
//  ────────
//  • `matchedGeometryEffect(id:in:properties:)` — with a *selective* `properties:`
//    set rather than the default all-of-them.
//  • `@Entry` in `EnvironmentValues` (iOS 18+) — one-line custom environment key.
//  • `.onGeometryChange(for:_:action:)` — live size of the compose field.
//  • `.defaultScrollAnchor(.bottom)` + `.safeAreaInset(edge: .bottom)` — chat log.
//  • `.keyframeAnimator(initialValue:trigger:content:keyframes:)` — the push-down
//    bounce, layered independently of the matched-geometry move.
//  • `withAnimation(_:completionCriteria: .removed) { } completion: { }` — drop the
//    transient flag only once the transition is really gone.
//
//  How to apply
//  ────────────
//  Reach for the overlay-twin pattern whenever a control's content should read as
//  becoming a row in a list: compose fields, a search bar promoting into results, a
//  form field turning into a card. The reusable idea is to keep the destination
//  mounted-but-invisible so a single id change can swap the pair.
//
import SwiftUI

/// The compose field is the only view that knows its measured size, and every
/// `MessageBubble` needs it — to cap its width at the field it flew out of, and to
/// scale the push-down offset. The two are siblings (field in a `safeAreaInset`,
/// bubbles in the `ScrollView`), so the size is published downwards instead of
/// threaded through `MessageBubble.init`, keeping that signature to the data it
/// actually renders.
///
/// `@Entry` (iOS 18+) is sugar for the old `EnvironmentKey` + `defaultValue` +
/// computed-property triple. The `.zero` here *is* that default value, and it is
/// what bubbles read on the first pass, before any measurement has landed.
extension EnvironmentValues {
    @Entry var messageFieldSize: CGSize = .zero
}

@available(iOS 26.0, *)
struct ChatBubbleTransitionToScrollViewDemo: View {
    @State private var allMessages: [Message] = Array(messages.prefix(3))
    @State private var currentMessage: Message = .init(message: dummyTitle)
    @State private var messageFieldSize: CGSize = .zero
    @Namespace private var namespace
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(allMessages) { message in
                    /// The message being composed is already in `allMessages` but must not draw here
                    /// yet — its twin over the text field owns the shared matched-geometry id until
                    /// `sendMessage` swaps them.
                    let isVisible = currentMessage.id != message.id
                    MessageBubble(
                        isVisible: isVisible,
                        entry: message,
                        namespace: namespace
                    )
                }
            }
            .padding(15)
        }
        /// Pins the log to the newest message, so appending does not shift older content upward.
        .defaultScrollAnchor(.bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar()
        }
        .environment(\.messageFieldSize, messageFieldSize)
    }

    private func bottomBar() -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Type a message", text: $currentMessage.message, axis: .vertical)
                .font(.body)
                .lineLimit(6)
                .padding(Constants.hPadding)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 25))
                /// The transition source sits *on* the field rather than replacing it, so the real
                /// `TextField` keeps focus and its keyboard while the copy flies away. Aligned
                /// `.topLeading` because that corner is where the field's own text starts, and the two
                /// have to be indistinguishable at rest.
                .overlay(alignment: .topLeading) {
                    ForEach(allMessages) {
                        if currentMessage.id == $0.id {
                            temporaryMessageTransitionSource(currentMessage)
                        }
                    }
                }
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    messageFieldSize = newValue
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .disabled(currentMessage.message.isEmpty)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    /// Mirrors `MessageBubble`'s styling exactly — matched geometry interpolates frames, not
    /// appearance, so any difference between the pair shows as a pop at either end of the flight.
    @ContentBuilder
    private func temporaryMessageTransitionSource(_ entry: Message) -> some View {
        let isFit = entry.isFit ?? false

        Text(entry.message)
            .font(.body)
            .padding(Constants.hPadding)
            .frame(maxWidth: isFit ? .infinity : nil, alignment: .leading)
            .background(Color(UIColor.systemGray6))
            .clipShape(.rect(cornerRadius: 25))
            /// Single-line text opts out of `.size`: source and destination already agree on width,
            /// so animating size would only make the box breathe. Wrapped text needs it — the field
            /// is full-width and the bubble is not, so the box has to shrink as it travels.
            .matchedGeometryEffect(id: entry.id, in: namespace,
                                   properties: isFit ? [.position, .size] : [.position])
    }

    private func sendMessage() {
        let textWidth = UIFont.preferredFont(forTextStyle: .body)
            .toSize(currentMessage.message)
            .width
        let contentPadding: CGFloat = 2 * Constants.hPadding
        /// Measured rather than observed: the layout that would reveal wrapping does not exist until
        /// after the bubble is inserted, and `properties:` has to be decided before that.
        let isFit = textWidth < (messageFieldSize.width - contentPadding)
        currentMessage.isFit = isFit
        allMessages.append(currentMessage)
        /// The append above needs a layout pass to land before the source is torn down. Clearing
        /// `currentMessage` in the same run loop leaves matched geometry with no destination
        /// registered for the id, and the message jumps instead of flying.
        DispatchQueue.main.async {
            let reference = currentMessage

            withAnimation(animation, completionCriteria: .removed) {
                currentMessage = .init(message: "")
            } completion: {
                /// `isFit` only exists to configure the transition; once the source is gone (`.removed`)
                /// it is cleared so a settled bubble sizes to its content like any other row.
                if let index = allMessages.firstIndex(where: { $0.id == reference.id }) {
                    allMessages[index].isFit = nil
                }
            }
        }
    }

    private var animation: Animation {
        .linear(duration: 0.3)
    }
}

struct MessageBubble: View {
    var isVisible: Bool
    var entry: Message
    var namespace: Namespace.ID
    /// View Properties
    /// Arrives through the environment rather than `init`, because the view that measures it is a sibling
    /// subtree, not an ancestor of this one. See the `@Entry` note at the top of the file.
    @Environment(\.messageFieldSize) private var messageFieldSize
    var body: some View {
        let isFit = entry.isFit ?? false

        /// The wrapper stays mounted while the text does not, which is what makes `isVisible` usable as
        /// the keyframe trigger below: the animator has to already exist to observe the flip. A bare `if`
        /// here would insert animator and content together and the push-down would never run.
        ZStack {
            if isVisible {
                Text(entry.message)
                    .font(.body)
                    .padding(Constants.hPadding)
                    .frame(maxWidth: isFit ? .infinity : nil, alignment: .leading)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(.rect(cornerRadius: 25))
                    .matchedGeometryEffect(
                        id: entry.id,
                        in: namespace,
                        properties: isFit ? [.position, .size] : [.position]
                    )
                    .padding(.top, 10)
            }
        }
        /// A wrapped bubble asks for `.infinity` width so its frame matches the full-width field it is
        /// flying out of. Turning `fixedSize` on only once this bubble is the visible one collapses that
        /// greedy frame back to the text's own width after it lands.
        .fixedSize(horizontal: isFit ? isVisible : false, vertical: true)
        .compositingGroup()
        /// Optional: a short push-down that reads as the log absorbing the new message. It is layered on
        /// top of the matched-geometry move rather than part of it, so dropping it leaves the transition
        /// itself intact.
        ///
        /// The capture list freezes `messageFieldSize` for the run of the animation. Reading the
        /// environment from inside the closure would let a mid-flight field or keyboard resize move the
        /// target the bounce is already partway toward.
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: isVisible) { [messageFieldSize] content, progress in
            content
                .offset(y: (messageFieldSize.height * 0.55) * progress)
        } keyframes: { _ in
            CubicKeyframe(1, duration: 0.15)
            CubicKeyframe(0, duration: 0.15)
        }
        /// Two frames, two jobs: the first caps a bubble at the width of the field it came from, so a long
        /// message can never end up wider than its own source; the second spans the row and pushes that
        /// capped box to the trailing edge.
        .frame(maxWidth: messageFieldSize.width, alignment: .trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private enum Constants {
    static let hPadding: CGFloat = 12
}

@available(iOS 26.0, *)
#Preview {
    ChatBubbleTransitionToScrollViewDemo()
}
