//
//  InlineToastView.swift
//  animation
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
