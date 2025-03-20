//
//  SpinnerButton.swift
//  animation

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

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .animation(.linear(duration: 0.2)) {
                $0
                    .scaleEffect(configuration.isPressed ? 0.9 : 1)
            }
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
