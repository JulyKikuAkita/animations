//
//  InlineToastView.swift
//  animation
//
//  Learning point
//  ──────────────
//  In-flow ("inline") toast — pushes neighbours apart to make
//  room rather than overlaying the screen like classic toasts.
//  Used for FORM-LEVEL feedback: "Incorrect password" appearing
//  above the Sign In button, or "Password reset email sent"
//  next to the Forgot Password link. Native-iOS-Settings feel.
//
//  Why inline > overlay for form feedback
//  ──────────────────────────────────────
//  Overlay toasts (HUD-style, this folder's
//  `[[ToastView+IOS18]]` and `[[LiquidGlassToastView+IOS26]]`)
//  cover other UI. Inline toasts shift content out of the way,
//  so the user sees BOTH the error AND the field that triggered
//  it without any visual occlusion. Perfect for validation,
//  inline status, contextual hints.
//
//  The trick: `.inlineToast(...)` modifier
//  ───────────────────────────────────────
//  Wraps the host view in a `VStack` whose anchor is configurable:
//
//      VStack(spacing: 10) {
//          if config.anchor == .bottom { self.compositingGroup() }
//          if isPresented {
//              InlineToastView(config: config)
//                  .transition(CustomToastTransition(...))
//          }
//          if config.anchor == .top { self.compositingGroup() }
//      }
//      .clipped()
//
//  Two flags control placement:
//    • **`anchor`** (`.top` / `.bottom`) — should the toast
//      appear ABOVE or BELOW the host view in the layout?
//    • **`animationAnchor`** (`.top` / `.bottom`) — which edge
//      should the toast SLIDE OUT to during exit transition?
//
//  Decoupling these lets you, e.g., have a toast that sits ABOVE
//  the button (anchor: .top) but slides out the BOTTOM
//  (animationAnchor: .bottom) — gives the appearance of "tucking
//  back into" the button on dismiss.
//
//  Why a custom `Transition` (not `.move(edge:)`)
//  ──────────────────────────────────────────────
//      visualEffect { content, proxy in
//          content.offset(y: phase.isIdentity ? 0 : ±height)
//      }
//
//  `.move(edge: .top)` would move the toast a FIXED distance
//  off-screen, which doesn't account for the toast's actual
//  height. Reading `proxy.size.height` inside `visualEffect`
//  ensures the slide distance matches the toast's measured
//  height — perfect alignment with the parent's `.clipped()`
//  bounds, no premature reveal.
//
//  Why `.compositingGroup()` on the host view
//  ──────────────────────────────────────────
//  When the toast inserts/removes, the host (button, etc.) is
//  shifted by the toast's height. Without `compositingGroup`,
//  the host's individual leaves can desync (text moves before
//  background), producing a jelly-jiggle. Flattening into a
//  single layer makes the shift atomic.
//
//  Visual style: stripe + tinted background
//  ────────────────────────────────────────
//      ZStack {
//          Rectangle().fill(.background)
//          HStack(spacing: 0) {
//              Rectangle().fill(config.tint).frame(width: 5)   // left stripe
//              Rectangle().fill(config.tint.opacity(0.15))     // tinted body
//          }
//      }
//
//  A 5pt left stripe + a 15%-opacity tinted body matches the
//  iOS Settings/System Status visual language. Swap for a
//  capsule or rounded rect for different brand feels.
//
//  Key APIs
//  ────────
//  • Custom `Transition` reading `proxy.size` — height-aware
//    slide.
//  • `.transition(.identity)` on icon / button children to
//    suppress the default per-child fade.
//  • `.compositingGroup()` for atomic neighbour shift.
//  • `.clipped()` on the wrapping VStack to hide the toast
//    while it's outside its identity position.
//
//  How to apply
//  ────────────
//  Use for inline form validation, login errors, save
//  confirmations next to a save button, schema-level warnings.
//  Pair with `withAnimation(.smooth(duration: 0.35))` on the
//  parent to drive the slide.
//
//  See also
//  ────────
//  • LiquidGlassToastView+IOS26.swift — sister overlay-style
//    toast for app-wide notifications.
//  • ToastView+IOS18.swift — interactive stacked HUD toasts.
//

import SwiftUI

struct InlineToastDemoView: View {
    @State private var showToast1: Bool = false
    @State private var showToast2: Bool = false
    var body: some View {
        NavigationStack {
            let toast1 = InlineToastConfig(
                icon: "exclamationmark.circle.fill",
                title: "Incorrect password",
                subtitle: "Try again",
                tint: .red,
                anchor: .top,
                animationAnchor: .bottom,
                actionIcon: "xmark"
            ) {
                showToast1 = false
            }

            let toast2 = InlineToastConfig(
                icon: "checkmark.circle.fill",
                title: "Password reset email sent",
                subtitle: "",
                tint: .green,
                anchor: .top,
                animationAnchor: .top,
                actionIcon: "xmark"
            ) {
                showToast2 = false
            }
            VStack(alignment: .leading, spacing: 15) {
                Text("Email Address")
                    .font(.caption)
                    .foregroundStyle(.gray)

                TextField("Enter your email address", text: .constant(""))

                Text("Password")
                    .font(.caption)
                    .foregroundStyle(.gray)

                SecureField("Enter your password", text: .constant(""))

                VStack(alignment: .trailing, spacing: 20) {
                    Button {
                        showToast1.toggle()
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                    }
                    .tint(.blue)
                    .buttonBorderShape(.roundedRectangle(radius: 10))
                    .buttonStyle(.borderedProminent)

                    Button("Forgot Password?") {
                        showToast2.toggle()
                    }
                    .inlineToast(alignment: .center, config: toast1, isPresented: showToast1)
                    .inlineToast(alignment: .trailing, config: toast2, isPresented: showToast2)
                }
                .padding(.top, 10)

                Spacer()
            }
            .textFieldStyle(.roundedBorder)
            .padding(15)
            .navigationTitle(Text("Sign In"))
            .animation(.smooth(duration: 0.35, extraBounce: 0), value: showToast1)
            .animation(.smooth(duration: 0.35, extraBounce: 0), value: showToast2)
        }
    }
}

extension View {
    func inlineToast(
        alignment: Alignment,
        config: InlineToastConfig,
        isPresented: Bool
    ) -> some View {
        VStack(spacing: 10) {
            if config.anchor == .bottom {
                self
                    .compositingGroup()
                    .frame(maxWidth: .infinity, alignment: alignment)
            }

            if isPresented {
                InlineToastView(config: config)
                    .transition(CustomToastTransition(anchor: config.animationAnchor))
            }

            if config.anchor == .top {
                self.compositingGroup()
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .clipped()
    }
}

private struct CustomToastTransition: Transition {
    var anchor: InlineToastConfig.InlineToastAnchor
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .visualEffect { [phase] content, proxy in
                content
                    .offset(y: offset(proxy, phase: phase))
            }
            /// clipped the view to avoid appear on top of other views
            .clipped()
    }

    nonisolated func offset(_ proxy: GeometryProxy, phase: TransitionPhase) -> CGFloat {
        let height = proxy.size.height + 10
        return anchor == .top ? (phase.isIdentity ? 0 : -height) : (phase.isIdentity ? 0 : height)
    }
}

struct InlineToastConfig {
    var icon: String
    var title: String
    var subtitle: String
    var tint: Color
    var anchor: InlineToastAnchor = .top
    var animationAnchor: InlineToastAnchor = .top
    var actionIcon: String
    var actionHandler: () -> Void = {}

    enum InlineToastAnchor {
        case top, bottom
    }
}

struct InlineToastView: View {
    var config: InlineToastConfig
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: config.icon)
                .font(.title2)
                .foregroundStyle(config.tint)

            VStack(alignment: .leading, spacing: 5) {
                Text(config.title)
                    .font(.callout)
                    .fontWeight(.semibold)

                if !config.subtitle.isEmpty {
                    Text(config.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }

            Spacer(minLength: 0)

            /// Action Button
            Button(action: config.actionHandler) {
                Image(systemName: config.actionIcon)
                    .foregroundStyle(.gray)
                    .contentShape(.rect)
            }
        }
        .padding()
        .background {
            ZStack {
                Rectangle()
                    .fill(.background)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(config.tint)
                        .frame(width: 5)

                    Rectangle()
                        .fill(config.tint.opacity(0.15))
                }
            }
        }
        .contentShape(.rect)
    }
}

#Preview {
    InlineToastDemoView()
}
