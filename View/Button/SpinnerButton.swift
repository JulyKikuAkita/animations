//
//  SpinnerButton.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Multi-stage transactional button — unlike [[CustomButton]]'s
//  binary success/fail, this one walks through several states with
//  distinct visuals:
//    .idle → .analyzing → .processing → (.failed | .completed)
//
//  Each state has its own label, icon, and tint, so the button is
//  effectively a tiny progress indicator that happens to be shaped
//  like a button. Two transition modifiers do the heavy lifting:
//    • `.contentTransition(.interpolate)` on the Text — smoothly
//      morphs glyph-to-glyph as the label changes.
//    • `.transition(.blurReplace)` on each icon — fades out the
//      old SF Symbol and blurs in the new one rather than a hard cut.
//
//  Spinner integration: while `isLoading == true`, an
//  `AnimatedSpinnerView(...)` (helper defined elsewhere in the repo)
//  renders in the icon slot. The state-driven icon takes over once
//  loading flips to `false`.
//
//  Key APIs
//  ────────
//  • `.contentTransition(.interpolate)` — iOS 17+. Per-glyph morph
//    instead of a fade-replace.
//  • `.transition(.blurReplace)` — iOS 17+. Soft icon swap.
//  • `.animation(_:value:)` chained per property — keeps each
//    state-change's animation tuned independently (icon vs. label
//    vs. tint).
//  • `ButtonTransactionState` enum — owns its own `.color` /
//    `.icon` / `.label` mappings so the body stays declarative.
//
//  How to apply
//  ────────────
//  Use whenever a single tap triggers MULTI-PHASE async work and
//  the user benefits from per-phase feedback (payment flow, KYC
//  upload, model inference). For binary success/fail flows reach
//  for [[CustomButton]] — it's lighter.
//
//  See also
//  ────────
//  • CustomButton.swift — binary-state cousin; compare to pick by
//    state-machine complexity.
//  • DrawerButtonView.swift — duplicate `ScaleButtonStyle`;
//    consolidate.
//
import SwiftUI

struct AnimatedSpinnerButtonDemoView: View {
    @State private var transactionState: ButtonTransactionState = .idle
    var body: some View {
        NavigationStack {
            VStack {
                let config = AnimatedSpinnerButton.Config(
                    title: transactionState.rawValue,
                    foregroundColor: .white,
                    background: transactionState.color,
                    symbolImage: transactionState.image
                )

                AnimatedSpinnerButton(config: config) {
                    transactionState = .analyzing
                    try? await Task.sleep(for: .seconds(2))
                    transactionState = .processing
                    try? await Task.sleep(for: .seconds(2))
                    transactionState = .failed
                    try? await Task.sleep(for: .seconds(1))
                    transactionState = .idle
                }
                .animation(.easeInOut(duration: 0.25), value: transactionState)
            }
            .navigationTitle("Spinner Button")
        }
    }
}

struct AnimatedSpinnerButton: View {
    var config: Config
    var shape: AnyShape = .init(Capsule())
    var onTap: () async -> Void
    /// View Properties
    @State private var isLoading: Bool = false
    var body: some View {
        Button {
            Task {
                isLoading = true
                await onTap()
                isLoading = false
            }
        } label: {
            HStack(spacing: 10) {
                if let symbolImage = config.symbolImage {
                    Image(systemName: symbolImage)
                        .font(.title3)
                        .transition(.blurReplace)
                } else {
                    if isLoading {
                        AnimatedSpinnerView(tint: config.foregroundColor, linedWidth: 4)
                            .frame(width: 20, height: 20)
                            .transition(.blurReplace)
                    }
                }

                Text(config.title)
                    .contentTransition(.interpolate)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, config.hPadding)
            .padding(.vertical, config.vPadding)
            .foregroundStyle(config.foregroundColor)
            .background(config.background.gradient)
            .clipShape(shape) // visual clipping
            .contentShape(shape) // gesture matches the shape (otherwise only text is interactive)
        }
        .disabled(isLoading) /// disable when task is performing
        .buttonStyle(ScaleButtonStyle())
        .animation(config.animation, value: config)
        .animation(config.animation, value: isLoading)
    }

    struct Config: Equatable {
        var title: String
        var foregroundColor: Color
        var background: Color
        var symbolImage: String?
        var hPadding: CGFloat = 15
        var vPadding: CGFloat = 10
        var animation: Animation = .easeInOut(duration: 0.2)
    }
}

enum ButtonTransactionState: String {
    case idle = "Click to pay"
    case analyzing = "Analyzing Transaction"
    case processing = "Processing Transaction"
    case completed = "Transaction Completed"
    case failed = "Transaction Failed"

    var color: Color {
        switch self {
        case .idle:
            Color.black
        case .completed:
            Color.green
        case .analyzing:
            Color.blue
        case .processing:
            Color(red: 0.8, green: 0.35, blue: 0.2)
        case .failed:
            Color.red
        }
    }

    var image: String? {
        switch self {
        case .idle: "apple.logo"
        case .analyzing: nil
        case .processing: nil
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }
}

#Preview {
    AnimatedSpinnerButtonDemoView()
}
