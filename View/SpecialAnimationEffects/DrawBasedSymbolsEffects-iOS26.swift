//
//  DrawBasedSymbolsEffects-iOS26.swift
//  animation
//
//  Created on 7/19/25.
//
//  Learning point
//  ──────────────
//  Apple-onboarding style sheet that loops through 3+ icons, each
//  one drawing itself onto the screen stroke-by-stroke (like a
//  pen sketching) before fading and yielding to the next. Built on
//  iOS 26's new `.symbolEffect(.drawOn.individually)` transition.
//
//  How `drawOn.individually` differs from `.drawOn`
//  ────────────────────────────────────────────────
//    • `.drawOn` — animates the whole symbol's path as a single
//      continuous stroke.
//    • `.drawOn.individually` — animates each *sub-glyph* of a
//      multi-component symbol one at a time. Useful for symbols
//      like `chart.bar.xaxis.ascending` where each bar should
//      appear sequentially, not all at once.
//
//  Why a recursive `loopSymbols()` instead of `repeatForever`?
//  ──────────────────────────────────────────────────────────
//  The animation is async (each symbol has its own `preDelay` /
//  `postDelay`). `withAnimation(.repeatForever)` doesn't compose
//  with `await Task.sleep` cleanly, so we drive the loop
//  manually:
//
//      func loopSymbols() async {
//          for index in data.indices { await loopSymbol(index) }
//          guard !isDisappear else { return }
//          try? await Task.sleep(for: .seconds(loopDelay))
//          await loopSymbols()  // tail-recursive; Swift handles the stack
//      }
//
//  The `isDisappear` guard breaks the recursion when the sheet
//  dismisses, preventing a runaway loop after `onDisappear`.
//
//  Per-symbol pre/post delay
//  ─────────────────────────
//  Each `SymbolData` has independent `preDelay` (wait before draw)
//  and `postDelay` (hold drawn before fading). Lets the rhythm of
//  the sequence breathe — large complex icons get longer holds, a
//  simple chevron gets a snappy beat.
//
//  Why `.glassProminent` button style + `.geometryGroup`?
//  ──────────────────────────────────────────────────────
//    • `.buttonStyle(.glassProminent)` — iOS 26's new translucent
//      tinted button style (replaces older `.borderedProminent`
//      with materials).
//    • `.geometryGroup()` on the symbol container AND the title
//      block — coalesces all child geometry changes into one
//      animation pass. Without it, the symbol fade and the title
//      `.contentTransition(.numericText())` swap can fight.
//
//  Key APIs
//  ────────
//  • `.symbolEffect(.drawOn.individually)` — iOS 26 transition.
//  • `.contentTransition(.numericText())` — animates text swaps as
//    rolling characters.
//  • `Task.sleep(for: .seconds(...))` — modern non-blocking delay.
//  • `.presentationDetents([.height(320)])` — fixed-height sheet.
//  • `.interactiveDismissDisabled()` — prevents pull-to-dismiss
//    interrupting the animation.
//
//  How to apply
//  ────────────
//  Use for first-run onboarding, feature reveals, or premium
//  upsell sheets where each value-prop deserves its own beat. The
//  recursive-async-loop pattern generalises to any "play a list of
//  beats forever, with cleanup on dismiss" UI.
//
import SwiftUI

@available(iOS 26.0, *)
struct DrawBasedSymbolsEffectsDemoView: View {
    @State private var isActive: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Start animation") {
                    isActive = true
                }
            }
            .navigationTitle(Text("DrawOnSymbolsEffects"))
        }
        .sheet(isPresented: $isActive) {
            DrawOnSymbolsEffects(tint: .pink, data: [
                .init(
                    name: "chart.bar.xaxis.ascending",
                    title: "Category Expenses",
                    subtitle: "Categorize your expenses to see\n where your money is going",
                    preDelay: 0.3
                ),
                .init(
                    name: "magnifyingglass.circle",
                    title: "Spending Habits",
                    subtitle: "See how your spending habits\n compare to others",
                    preDelay: 1.6
                ),
                .init(
                    name: "square.and.arrow.up",
                    title: "Export Your Data",
                    subtitle: "Share your expenses with\n your bank or financial advisor",
                    symbolSize: 65,
                    preDelay: 1.2
                ),
            ])
        }
    }
}

@available(iOS 26.0, *)
struct DrawOnSymbolsEffects: View {
    var tint: Color = .blue
    var loopDelay: CGFloat = 0.7
    @State var data: [SymbolData]
    @State private var currentIndex: Int = 0
    @State private var isDisappear = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 25) {
            ZStack {
                ForEach(data) { symbolData in
                    if symbolData.drawOn {
                        Image(systemName: symbolData.name)
                            .font(
                                .system(
                                    size: symbolData.symbolSize,
                                    weight: .regular // semmibild weight cause weired animation
                                )
                            )
                            .foregroundStyle(.white)
                            .transition(.symbolEffect(.drawOn.individually))
                    }
                }
            }
            .frame(width: 120, height: 120)
            .background {
                RoundedRectangle(cornerRadius: 35, style: .continuous)
                    .fill(tint.gradient)
            }
            .geometryGroup()

            /// Title & subtitle animation
            VStack(spacing: 6) {
                Text(data[currentIndex].title)
                    .font(.title2)
                    .lineLimit(1)

                Text(data[currentIndex].subtitle)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .contentTransition(.numericText())
            .animation(
                .snappy(duration: 1, extraBounce: 0),
                value: currentIndex
            )
            .fontDesign(.rounded)
            .frame(maxWidth: 300)
            .frame(height: 80)
            .geometryGroup()

            Button {
                dismiss()
            } label: {
                Text("Start Saving")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 2)
            }
            .tint(tint.opacity(0.7))
            .buttonStyle(.glassProminent)
        }
        .frame(height: 320)
        .presentationDetents([.height(320)])
        .interactiveDismissDisabled() // disable dropdown to dismiss sheet
        .task {
            await loopSymbols()
        }
        .onDisappear {
            isDisappear = true
        }
    }

    private func loopSymbols() async {
        for index in data.indices {
            await loopSymbol(index)
        }
        guard !isDisappear else { return }
        /// Delay to finish the final round of loop animation
        try? await Task.sleep(for: .seconds(loopDelay))
        await loopSymbols()
    }

    private func loopSymbol(_ index: Int) async {
        let symbolData = data[index]
        /// Apply pre-delay
        try? await Task.sleep(for: .seconds(symbolData.preDelay))

        /// draw symbol
        data[index].drawOn = true
        currentIndex = index

        /// Apply post-delay
        try? await Task.sleep(for: .seconds(symbolData.postDealy))

        /// remove symbol
        data[index].drawOn = false
    }
}

struct SymbolData: Identifiable {
    var id: UUID = .init()
    /// properties
    var name: String
    var title: String
    var subtitle: String
    var symbolSize: CGFloat = 70
    var preDelay: CGFloat = 1
    var postDealy: CGFloat = 2
    fileprivate var drawOn: Bool = false
}

@available(iOS 26.0, *)
#Preview {
    DrawBasedSymbolsEffectsDemoView()
}
