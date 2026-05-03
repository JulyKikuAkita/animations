//
//  BorderBeamTextFieldView.swift
//  animation
//
//  Created on 5/2/26.
//
// Consumer/demo for the `.borderBeam(...)` modifier defined in
// `View/TextEffectView/BorderBeamEffect.swift`.
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. One modifier, two shapes.
//    Same `.borderBeam(...)` call drives:
//      • A rounded card (the whole text-field container)
//      • A small circular button (the arrow-up send button)
//    Works on any rounded-rect shape; the `cornerRadius` parameter decides
//    whether you get a pill, a circle, or a rounded card.
//
// 2. Toggling the effect.
//    Pass a `Bool` through `isEnabled:` bound to `@State enableBeamEffect`.
//    When `false`, the modifier falls back to a no-op so the view renders
//    plainly with no beam — the tap on the arrow button flips it on.
//
// 3. Layering with `.background(in: shape)`.
//    `.background(.gray.opacity(0.1), in: .rounded())` and
//    `.background(.background, in: .circle)` — the `in:` overload takes a
//    shape and applies the fill through it, so we don't need a separate
//    `.clipShape` call.
//
// See `BorderBeamEffect.swift` for how the effect itself is built.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

struct BorderBeamTextFieldDemoView: View {
    let beamColor: [Color] = [.indigo, .blue, .red, .yellow, .orange, .pink]
    let buttonBeamColor: [Color] = [.gray, .brown]
    @State private var enableBeamEffect: Bool = false
    @State private var beamStyle: BorderBeamStyle = .simple
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                ForEach(BorderBeamStyle.allCases, id: \.self) { style in
                    Text(style.rawValue.capitalized)
                        .frame(width: 180, height: 50)
                        .showBeamStyle(style)
                }
            }
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 25) {
                TextField("Ask Anything...", text: .constant(""))
                    .padding(.top, 8)

                HStack(spacing: 20) {
                    Button {} label: {
                        Text("Name/Model Name")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.8))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(.fill, in: .capsule)
                    }

                    Spacer(minLength: 0)

                    Group {
                        Button {
                            // Cycle through styles: simple → singleMask → masks → simple …
                            let all = BorderBeamStyle.allCases
                            let next = (all.firstIndex(of: beamStyle) ?? 0) + 1
                            beamStyle = all[next % all.count]
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button {} label: {
                            Image(systemName: "cloud")
                        }

                        Button {} label: {
                            Image(systemName: "mic")
                        }

                        Button {
                            enableBeamEffect.toggle()
                        } label: {
                            Image(systemName: "arrow.up")
                                .frame(width: 35, height: 35)
                                .borderBeam(
                                    border: .primary,
                                    beam: buttonBeamColor,
                                    beamBlur: 15,
                                    cornerRadius: 40,
                                    isEnabled: enableBeamEffect,
                                    style: beamStyle
                                )
                                .background(.background, in: .circle)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(15)
            .background(.gray.opacity(0.1), in: .rounded())
            .borderBeam(
                border: .primary,
                beam: beamColor,
                beamBlur: 25,
                cornerRadius: 20,
                isEnabled: enableBeamEffect,
                style: beamStyle
            )
        }
        .padding()
    }
}

// Palette hoisted to file scope so both `BorderBeamTextFieldDemoView.beamColor`
// and the `showBeamStyle` helper can reference one source of truth.
private let demoBeamPalette: [Color] = [.indigo, .blue, .red, .yellow, .orange, .pink]

private extension View {
    func showBeamStyle(
        _ style: BorderBeamStyle = .simple
    ) -> some View {
        modifier(
            BorderBeamEffect(
                border: .primary,
                hideFadeBorder: false,
                beam: demoBeamPalette,
                beamBlur: 15,
                cornerRadius: 20,
                isEnabled: true,
                style: style
            )
        )
    }
}

#Preview {
    BorderBeamTextFieldDemoView()
}
