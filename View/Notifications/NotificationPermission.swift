//
//  NotificationPermission.swift
//  animation
//
//  Created on 10/8/26.
//  Notification-permission sheet (iOS 27+): a looping "notifications
//  arrive → bell badges → everything clears" animation above the
//  title / primary / secondary buttons.
//
//  TODO: Cleanup candidates
//        1. The "Delay keyframe" is `LinearKeyframe(2, duration: 1)`,
//           which slides progress 3 → 2 (the top notification
//           un-arrives) before springing to 4. A hold would be
//           `LinearKeyframe(3, duration: 1)`.
//        2. `disableVerticalToolBar` is unused and its body is
//           commented out; either wire it up or delete it.
//
//  Learning point
//  ──────────────
//  Strategy: ONE timeline, MANY derived values. A single
//  `KeyframeAnimator` animates one `CGFloat` (`progress`, 0 → 4);
//  every subview computes its own state from that number instead of
//  owning its own animation. Nothing can drift out of sync, and the
//  whole sequence restarts as one unit via `repeating: true`.
//
//  Timeline (value → meaning):
//    0 → 0  hold 0.5s
//    0 → 1  notification #1 arrives      (spring)
//    1 → 2  notification #2 arrives      (spring)
//    2 → 3  notification #3 arrives      (spring)
//    3 → 4  dismiss: stack flies off, bell resets (spring)
//
//  Each view layer picks a different tool for the job:
//
//  • Notification stack — per-index slicing.
//    `indexProgress = progress - index` turns the global value into a
//    local 0…1 entrance for each card (opacity, 0.7 → 1 scale,
//    10 → 0 blur, -100 → 0 offset). Values past 1 are reused as
//    "how many cards arrived after me" to push older cards down 10pt
//    and shrink them 5% (anchor `.bottom`) — the stacking effect is
//    free, no extra state.
//
//  • Stack dismiss — `.visualEffect`.
//    `dismissProgress` (progress 3.2 → 4 remapped to 0 → 1) drives
//    blur / opacity / offset. `visualEffect` gives the view's own
//    size, so it can fly up by exactly its height without a
//    `GeometryReader` that would change layout.
//
//  • Bell — `GeometryReader` + cross-fade.
//    Here a `GeometryReader` IS wanted: the symbol is sized from the
//    available height (`size.height / 2`). Two symbols (`bell`,
//    `bell.badge`) are stacked and cross-faded by opacity rather than
//    swapping the `Image`, because a symbol swap can't be
//    interpolated frame-by-frame from `progress`. The ZStack must use
//    `.frame(maxWidth: .infinity, maxHeight: .infinity)` to centre —
//    `width: .infinity` is invalid and leaves it top-leading.
//
//  • Badge count — discrete value, so it needs its own transaction.
//    `count` is an `Int` derived from `progress.rounded()`. Keyframe
//    frames don't carry an animation transaction for that jump, so
//    `.contentTransition(.numericText())` only rolls the digit
//    because of the explicit `.animation(.linear, value: count)`.
//
//  • `compositingGroup()` before blur / opacity — flattens the glass
//    cards (or the two bells) first so they fade as one image instead
//    of each layer fading and showing the ones behind it.
//
//  Choosing the animation tool
//  ───────────────────────────
//  • `KeyframeAnimator` (this file) — timed, multi-step, looping
//    choreography where many properties derive from one value.
//  • `PhaseAnimator` — a few discrete states with an animation per
//    step; simpler, but values jump between phases, so no per-index
//    slicing.
//  • `Task` loop + `withAnimation` + sleep (see
//    `CustomNotificationsView.swift`) — when steps depend on async
//    work or need to be stopped / changed mid-way.
//
//  Key APIs
//  ────────
//  • `KeyframeAnimator(initialValue:repeating:)` with `MoveKeyframe`,
//    `LinearKeyframe`, `SpringKeyframe`.
//  • `.visualEffect { content, proxy in }` — geometry-aware effects
//    without affecting layout.
//  • `.onGeometryChange` + `concentricCornerRadii` → `containerShape`
//    so each card's `ConcentricRectangle` matches the sheet's corners.
//  • `.contentTransition(.numericText())` for the badge digit.
//
//  How to apply
//  ────────────
//  For any looping showcase animation, pick one scalar timeline,
//  write each element as a pure function of it, and offset elements
//  with `progress - index`. Add explicit `.animation(_:value:)` only
//  for values that change discretely.

import SwiftUI

@available(iOS 27.0, *)
struct EnableNotificationDemo: View {
    @State private var showPermissionView: Bool = false
    var body: some View {
        NavigationStack {}
            .sheet(isPresented: $showPermissionView) {
                NotificationPermissionView(config: .init()) {} secondaryAction: {}
            }
            .onAppear {
                showPermissionView = true
            }
    }
}

struct EnableNotificationPermissionConfig {
    var title: String = "Enable Push Notifications"
    var description: String = dummyTitle
    var tint: Color = .blue

    var primaryButtonTitle: String = "Enable Notifications"
    var secondaryButtonTitle: String = "Maybe Later"
    var showSecondaryButtonTitle: Bool = true

    var topNotification: Notification = .init()
    var centerNotification: Notification = .init()
    var bottomNotification: Notification = .init()

    struct Notification {
        var assetName: String = "fox"
        var title: String = "placeholder notification title"
        var caption: String = "placeholder notification description"
    }
}

@available(iOS 27.0, *)
struct NotificationPermissionView: View {
    var config: EnableNotificationPermissionConfig = .init()
    var primaryAction: () -> Void
    var secondaryAction: () -> Void
    /// View properties
    @State private var containerCornerRadius: CGFloat = 15
    @Environment(\.horizontalSizeClass) private var hClass
    @Environment(\.verticalSizeClass) private var vClass

    var body: some View {
        VStack(spacing: 10) {
            KeyframeAnimator(initialValue: CGFloat.zero, repeating: true) { progress in
                let dismissProgress = progress > 3.2 ? (progress - 3.2) / 0.8 : 0

                VStack(spacing: 15) {
                    notificationStack(progress)
                        .compositingGroup()
                        .visualEffect { content, proxy in
                            content
                                .blur(radius: 20 * dismissProgress)
                                .opacity(1 - dismissProgress)
                                .offset(y: -proxy.size.height * dismissProgress)
                        }

                    notificationBellView(progress, dismissProgress)
                }
            } keyframes: { _ in
                // 0-3 notification keyframe, 3-4 resetting keyframe
                MoveKeyframe(0)
                LinearKeyframe(0, duration: 0.5)
                SpringKeyframe(1, duration: 1, spring: .bouncy(duration: 0.9, extraBounce: 0.1))
                SpringKeyframe(2, duration: 1, spring: .bouncy(duration: 0.9, extraBounce: 0.1))
                SpringKeyframe(3, duration: 1, spring: .bouncy(duration: 0.9, extraBounce: 0.1))

                // Delay keyframe
                LinearKeyframe(2, duration: 1)
                SpringKeyframe(4, duration: 1, spring: .bouncy(duration: 0.9, extraBounce: 0))
            }
            // read concentric container value
            .onGeometryChange(for: CGFloat.self) {
                let radii = $0.concentricCornerRadii
                let topLeft = radii?.topLeading ?? 0
                let topRight = radii?.topTrailing ?? 0

                return max(max(topLeft, topRight), 15)
            } action: { newValue in
                containerCornerRadius = newValue
            }

            sheetContent()
        }
        .padding([.horizontal, .top], 15)
        .padding(.bottom, 20)
        .ignoresSafeArea(.all, edges: .bottom)
        .presentationDetents([.height(450)])
        .presentationSizing(.page.fitted(horizontal: true, vertical: false))
        .presentationCompactAdaptation(.sheet)
        .interactiveDismissDisabled()
//        .disableVerticalToolBar(status: vClass == .regular && hClass == .compact)
    }

    private func notificationStack(_ progress: CGFloat) -> some View {
        ZStack {
            ForEach(0 ..< 3, id: \.self) { index in
                let notification = index == 0 ? config.bottomNotification : index == 1 ? config.centerNotification : config.topNotification

                // animation value
                let indexProgress = progress - CGFloat(index)
                let progress = max(min(indexProgress, 1), 0)

                let offset = 10 * max(indexProgress - 1, 0)
                let scale = 1 - max(indexProgress - 1, 0) * 0.05

                notificationView(notification)
                    .compositingGroup()
                    .opacity(progress)
                    .scaleEffect(0.7 + (progress * 0.3))
                    .scaleEffect(scale, anchor: .bottom)
                    .blur(radius: 10 * (1 - progress))
                    .offset(y: -100 * (1 - progress))
                    .offset(y: offset)
            }
        }
    }

    private func notificationBellView(_ progress: CGFloat, _ dismissProgress: CGFloat) -> some View {
        GeometryReader {
            let size = $0.size
            let symbolSize = size.height / 2
            // animation value
            let offsetProgress = 1 - (min(progress / 3, 1) - dismissProgress)
            let opacity = min(progress, 1) - dismissProgress
            let count = max(min(Int(progress.rounded()), 3), 1)

            ZStack {
                Image(systemName: "bell")
                    .font(.system(size: symbolSize))
                    .foregroundStyle(.gray)
                    .opacity(1 - opacity)

                Image(systemName: "bell.badge")
                    .font(.system(size: symbolSize))
                    .foregroundStyle(.red, .gray)
                    .overlay(alignment: .topTrailing) {
                        let fontSize = symbolSize * 0.2

                        Text("\(count)")
                            .font(.system(size: fontSize, weight: .bold))
                            .frame(width: fontSize)
                            .fixedSize()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.linear, value: count)
                            .offset(x: -fontSize * 1.1, y: fontSize * 0.98)
                    }
                    .compositingGroup()
                    .opacity(opacity)
            }
            .compositingGroup()
            .offset(y: -30 * offsetProgress)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func notificationView(_ value: EnableNotificationPermissionConfig.Notification) -> some View {
        HStack(spacing: 8) {
            Image(value.assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(ConcentricRectangle(corners: .concentric, isUniform: true))

            VStack(alignment: .leading, spacing: 4) {
                Text(value.title)
                    .font(.callout)

                Text(value.caption)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .frame(height: 60)
        .glassEffect(.regular, in: ConcentricRectangle())
        .containerShape(.rect(cornerRadius: containerCornerRadius))
    }

    private func sheetContent() -> some View {
        VStack(spacing: 10) {
            Text(config.title)
                .font(.title3.bold())
                .lineLimit(1)

            Text(config.description)
                .multilineTextAlignment(.center)
                .font(.callout)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: primaryAction) {
                Text(config.primaryButtonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.glassProminent)
            .padding(.top, 15)
            .padding(.horizontal, 15)

            if config.showSecondaryButtonTitle {
                Button(config.secondaryButtonTitle, action: secondaryAction)
            }
        }
        .tint(config.tint)
    }
}

/// Duo specific modifier
extension View {
    @ContentBuilder
    func disableVerticalToolBar(status _: Bool) -> some View {
        if #available(iOS 27.1, *) {
            self
//                .toolbarVerticalBehavior(status ? .disabled : .automatic)
        } else {
            self
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    EnableNotificationDemo()
}
