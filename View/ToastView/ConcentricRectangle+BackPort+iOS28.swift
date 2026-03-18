//
//  ConcentricRectangle+BackPort+iOS28.swift
//  animation
//
//  Created on 3/17/26.

import SwiftUI

struct ConcentricRectangleIOS18DemoView: View {
    @Environment(\.self) private var env
    @State private var padding: CGFloat = 20
    var body: some View {
        ZStack {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .padding(10)
            }

            let deviceCornerRadius = extractDeviceCornerRadius(env) ?? 0
            RoundedRectangle(cornerRadius: deviceCornerRadius, style: .continuous)
                .inset(by: 10)
                .fill(.red.opacity(0.9))
                .concentricClipShape(true)

            Slider(value: $padding, in: 0 ... 100)
                .padding(20)
        }
        .padding(padding)
        .ignoresSafeArea()
    }
}

extension View {
    func concentricClipShape(_ isUniform: Bool) -> some View {
        modifier(ConcentricClipShape(isUniform: isUniform))
    }
}

private struct ConcentricClipShape: ViewModifier {
    var isUniform: Bool
    @State private var globalRect: CGRect = .zero
    @Environment(\.self) private var env
    func body(content: Content) -> some View {
        let clipShape = BackportedConcentricRectangle(env: env, globalRect: globalRect, isUniform: isUniform)
        content
            .clipShape(clipShape)
            .contentShape(clipShape)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                globalRect = newValue
            }
    }
}

struct CustomShapeCRDemoView: View {
    @Environment(\.self) private var env
    @State private var padding: CGFloat = 20
    var body: some View {
        ZStack {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .padding(10)
            }

            GeometryReader {
                let rect = $0.frame(in: .global)
                BackportedConcentricRectangle(env: env, globalRect: rect, isUniform: true)
                    .fill(.red.opacity(0.5))
            }

            Slider(value: $padding, in: 0 ... 100)
                .padding(20)
        }
        .padding(padding)
        .ignoresSafeArea()
    }
}

/// create customized shape for back port Concentric Rectangle to iOS 18
struct BackportedConcentricRectangle: Shape, @unchecked Sendable {
    let env: EnvironmentValues
    var globalRect: CGRect
    var isUniform: Bool
    @MainActor
    init(env: EnvironmentValues, globalRect: CGRect, isUniform: Bool = false) {
        self.env = env
        self.globalRect = globalRect
        self.isUniform = isUniform

        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen {
            deviceSize = screen.bounds.size
        } else {
            deviceSize = .zero
        }
    }

    private let deviceSize: CGSize

    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in

            let cornerRadius = extractDeviceCornerRadius(env) ?? 0
            let leading = globalRect.minX
            let trailing = deviceSize.width - globalRect.maxX
            let top = globalRect.minY
            let bottom = deviceSize.height - globalRect.maxY

            let tl = max(cornerRadius - max(top, leading), 0)
            let bl = max(cornerRadius - max(bottom, leading), 0)
            let bt = max(cornerRadius - max(bottom, trailing), 0)
            let tt = max(cornerRadius - max(top, trailing), 0)

            let maxValue = max(tl, max(bl, max(bt, tt)))

            path.addRoundedRect(in: rect, cornerRadii: .init(
                topLeading: isUniform ? maxValue : tl,
                bottomLeading: isUniform ? maxValue : bl,
                bottomTrailing: isUniform ? maxValue : bt,
                topTrailing: isUniform ? maxValue : tt
            ))
        }
    }
}

extension View {
    nonisolated func extractDeviceCornerRadius(_ env: EnvironmentValues) -> CGFloat? {
        let envText = String(describing: env)
        let pattern = /EnvironmentPropertyKey<DisplayCornerRadiusKey> = Optional\(([\d.]+)\)/
        guard let firstMatch = envText.firstMatch(of: pattern),
              let value = Float(firstMatch.1)
        else {
            return nil
        }
        return CGFloat(value)
    }
}

#Preview {
    CustomShapeCRDemoView()
}

#Preview {
    ConcentricRectangleIOS18DemoView()
}
