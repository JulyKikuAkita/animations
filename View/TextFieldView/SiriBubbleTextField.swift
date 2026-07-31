//
//  SiriBubbleTextField.swift
//  animation
//
//  Created on 7/31/26.
// iOS 27 Siri style dynamic island bubble + textFiled

import SwiftUI

@available(iOS 27.0, *)
struct SiriBubbleTextFieldDemoView: View {
    @State private var progress: CGFloat = 0
    @State private var text: String = ""
    @State private var safeArea: EdgeInsets = .init() // captured below; GeometryProxy.safeAreaInsets isn't reachable outside a reader
    @FocusState private var isKeyboardActive: Bool
    var body: some View {
        // Heuristic, not an API: no public check for "has Dynamic Island".
        // Island devices report top inset ~59; notch devices ~47; Home-button devices ~20-24.
        let hasDynamicIsland: Bool = safeArea.top >= 59

        ZStack(alignment: .top) {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .ignoresSafeArea()

            DynamicIslandBubbleTextField(
                hasDynamicIsland: hasDynamicIsland,
                progress: progress,
                buttonSymbol: "mic",
                hint: "Search or Ask",
                text: $text
            ) {}
                .focused($isKeyboardActive)
                // On island devices, pull the bubble up to overlap the island as it grows;
                // otherwise just nudge it below the status bar.
                .offset(y: hasDynamicIsland ? -(safeArea.top + 34 + (progress * 3)) / 2 : 5)

            VStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    Slider(value: $progress)
                }

                Button("Toggle Effect") {
                    withAnimation(.bouncy) {
                        progress = progress == 1 ? 0 : 1
                        isKeyboardActive = progress == 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
            }
            .padding(25)
            .glassEffect(.regular, in: .rect(cornerRadius: 30))
            .padding(.horizontal, 25)
            .frame(maxHeight: .infinity)
        }
        .onChange(of: isKeyboardActive) { _, newValue in
            if !newValue, progress == 1 {
                withAnimation(.bouncy) {
                    progress = 0
                }
            }
        }
        // Read safe-area insets once at layout time instead of wrapping the whole
        // view in a GeometryReader (which would also affect its children's sizing).
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            safeArea = newValue
        }
        /// available in iOS27
        // Hide the status bar while expanded so it doesn't visually collide with the bubble/keyboard.
        .toolbarVisibility(progress != 0 ? .hidden : .visible, for: .statusBar)
    }
}

@available(iOS 27.0, *)
struct DynamicIslandBubbleTextField: View {
    var hasDynamicIsland: Bool
    var progress: CGFloat
    var buttonSymbol: String
    var hint: String
    @Binding var text: String
    var buttonAction: () -> Void
    var body: some View {
        GeometryReader {
            let size = $0.size
            let extraWidth = size.width - 120
            // Remap the last 70% of expansion to 0...1 so text/icon only fade in
            // once the capsule is mostly expanded, instead of fading the whole way.
            let fadedProgress = ((cappedProgress - 0.3) / 0.7).clamped(to: 0 ... 1)

            let midDistance: Float = 0.5
            /// hide dynamic island
//            let row1: [Color] = Array(repeating: .black, count: 3)
//            let row2: [Color] = Array(repeating: .black.opacity(0.9), count: 3)
//            let row3: [Color] = Array(repeating: .black.opacity(0.3), count: 3)

            /// example for color mesh
            let row1: [Color] = [.black, .indigo, .black]
            let row2: [Color] = [.purple.opacity(0.85), .pink, .blue.opacity(0.85)]
            let row3: [Color] = Array(repeating: .black.opacity(0.3), count: 3)

            ZStack {
                // Mesh > linear here: rows are uniform (no horizontal variation), so today
                // this reads the same as a 3-stop vertical LinearGradient. MeshGradient earns
                // its keep once you want per-point color/position control (e.g. an off-center
                // glow) — a LinearGradient can't bend its stops like that.
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, midDistance], [0.5, midDistance], [1, midDistance],
                        [0, 1], [0.5, 1], [1, 1],
                    ],
                    colors: row1 + row2 + row3
                )

                /// Content
                HStack(spacing: 10) {
                    TextField(hint, text: $text)
                        .tint(.white)

                    Button(action: buttonAction) {
                        Image(systemName: buttonSymbol)
                            .foregroundStyle(.white.secondary)
                    }
                }
                .font(.title3)
                .compositingGroup()
                .blur(radius: 10 - (10 * fadedProgress))
                .opacity(fadedProgress)
                .padding(.horizontal, 30)
            }
            .frame(width: 120 + (extraWidth * cappedProgress))
            .clipShape(clipShape)
            // Tint fades from opaque black (minimized, matches the island) to clear glass
            // (expanded). Was `095` — a stray zero made this a bug: opacity went negative
            // past ~1% fadedProgress and clamped to 0 for the rest of the range.
            .glassEffect(.clear.tint(.black.opacity(1 - (0.95 * fadedProgress))), in: clipShape)
            // Non-island devices have nowhere to visually anchor to while collapsed,
            // so keep the bubble invisible until it's expanding.
            .opacity(hasDynamicIsland ? 1 : fadedProgress)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        /// Capsule size: minimized: 35, expanded: 100
        .frame(height: 35 + (65 * cappedProgress))
        .padding(.horizontal, 15)
        // Island devices stay pinned under the island (handled by the offset above this
        // view); everything else slides the bubble down from off-screen as it expands.
        .offset(y: hasDynamicIsland ? 0 : (-100 + (100 * cappedProgress)))
        // Force dark scheme so the white TextField/placeholder stay legible against the
        // black glass tint regardless of the system appearance.
        .environment(\.colorScheme, .dark)
    }

    private var clipShape: some Shape {
        Capsule(style: .continuous)
    }

    private var cappedProgress: CGFloat {
        progress.clamped(to: 0 ... 1)
    }
}

@available(iOS 27.0, *)
#Preview {
    SiriBubbleTextFieldDemoView()
}
