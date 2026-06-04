//
//  HackerTextView.swift
//  animation
//
//  Learning point
//  ──────────────
//  "Hacker / Matrix" text-reveal effect: each character cycles through
//  random glyphs for a random duration before settling on its real
//  value. Reads like a movie hacker terminal decrypting in real time.
//
//  Three implementation ideas worth understanding:
//    1. **Per-character independent timing.** Each index gets its own
//       `Timer` whose `delay` is `random(0...duration)`. The result:
//       characters resolve in a non-uniform wave rather than a uniform
//       sweep. This is what makes it feel organic instead of mechanical.
//    2. **`animationID` as a generation counter.** When the user
//       triggers a new animation mid-flight, we issue a fresh UUID;
//       any stale timers compare their captured `currentID` to the
//       current `animationID` and `invalidate()` themselves. No
//       `Timer.invalidate` chasing, no shared cancellation token.
//    3. **`.contentTransition(...)` per character.** Setting the
//       transition on the whole `Text` makes each character swap blend
//       (e.g. `.numericText()`, `.interpolate`, `.identity`) when the
//       string changes. Combined with `monospaced` font design so the
//       width never reflows mid-scramble.
//
//  Why monospaced?
//  ───────────────
//  Without `fontDesign(.monospaced)`, the layout would jitter as
//  `m` swaps to `i`, etc. Fixed-width keeps every character cell the
//  same size so only the glyph changes — an essential visual trick
//  for any character-level animation.
//
//  Key APIs
//  ────────
//  • `Timer.scheduledTimer(withTimeInterval:repeats:_:)` — per-char
//    cadence. Each `timer.fire()` runs the first tick immediately.
//  • `.contentTransition(_:)` — pluggable per-char transition style.
//  • `.fontDesign(.monospaced)` — stable cell widths during scramble.
//  • `customOnChange` (project helper) — same shape as `.onChange` but
//    with a single closure (legacy or sugar; check the helper file).
//
//  How to apply
//  ────────────
//  Use for splash screens, password reveals, "decrypting…" UX, terminal
//  output. The generation-counter cancellation pattern (#2 above) is
//  the reusable nugget — works any time you have N independent timers
//  and need a clean way to abort a stale generation.
//
//  See also
//  ────────
//  • GlitchTextEffectView.swift — sister text-effect that's animated
//    via KeyframeAnimator; useful comparison of timer-driven vs
//    keyframe-driven approaches.
//
import SwiftUI

struct HackerTextDemoView: View {
    let dummyDescription: String = "The answer to life, the universe, and everything."

    @State private var trigger: Bool = false
    @State private var text = "The Hitchhiker's Guide to the Galaxy"
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HackerTextView(
                text: text,
                trigger: trigger,
                transition: .identity, // .identity // .interpolate // .numericText()
                speed: 0.01
            )
            .font(.largeTitle.bold())
            .lineLimit(4)

            Button(action: {
                if text == "🐕" {
                    text = "The Hitchhiker's Guide to the Galaxy"
                } else if text == "The Hitchhiker's Guide to the Galaxy" {
                    text = dummyDescription
                } else if text == dummyDescription {
                    text = "42"
                } else {
                    text = "🐕" // multiple emoji crashes preview
                }
                trigger.toggle()
            }, label: {
                Text("Trigger")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 2)
            })
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HackerTextView: View {
    /// Config
    var text: String
    var trigger: Bool
    var transition: ContentTransition = .interpolate
    var duration: CGFloat = 1.0
    var speed: CGFloat = 0.1

    /// View Properties
    @State private var animatedText = ""
    @State private var randomCharacters: [Character] = {
        let string = "abcdefghijklmnopqrstuvwxyz1234567890-=!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return Array(string)
    }()

    @State private var animationID: String = UUID().uuidString

    var body: some View {
        Text(animatedText)
            .fontDesign(.monospaced) // ensure same horizontal space for all characters
            .truncationMode(.tail)
            .contentTransition(transition)
            .animation(.easeInOut(duration: 0.1), value: animatedText)
            .onAppear {
                guard animatedText.isEmpty else { return }
                setRandomCharacters()
                animateText()
            }
            .customOnChange(value: trigger) { _ in
                animateText()
            }
            .customOnChange(value: text) { _ in
                animatedText = text
                animationID = UUID().uuidString
                setRandomCharacters()
                animateText()
            }
    }

    /// Tip: generation-counter cancellation.
    /// `currentID` captures the animation ID at scheduling time; if the
    /// user triggers a new animation, `animationID` is rotated to a new
    /// UUID. Any stale timer notices `currentID != animationID` on its
    /// next tick and self-invalidates. Avoids tracking timer references
    /// or sharing a `Bool` cancel flag across N timers.
    private func animateText() {
        let currentID = animationID
        for index in text.indices {
            // Per-char random delay = wave-of-decryption look.
            let delay = CGFloat.random(in: 0 ... duration)
            var timerDuration: CGFloat = 0

            let timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
                if currentID != animationID {
                    timer.invalidate()
                } else {
                    timerDuration += speed
                    if timerDuration >= delay {
                        // Past this character's resolve time — write the
                        // real glyph and stop scrambling this index.
                        if text.indices.contains(index) {
                            let actualCharacter = text[index]
                            replaceCharacter(at: index, character: actualCharacter)
                        }

                        timer.invalidate()
                    } else {
                        // Still scrambling — paint a random glyph.
                        guard let randomCharacter = randomCharacters.randomElement() else { return }
                        replaceCharacter(at: index, character: randomCharacter)
                    }
                }
            }
            // `fire()` runs the first tick now instead of waiting for the
            // first scheduled interval — avoids visible delay before the
            // scramble begins.
            timer.fire()
        }
    }

    private func setRandomCharacters() {
        animatedText = text
        for index in animatedText.indices {
            guard let randomCharacter = randomCharacters.randomElement() else { return }
            replaceCharacter(at: index, character: randomCharacter)
        }
    }

    /// Tip: skip whitespace cells so spaces stay spaces.
    /// Without the trimming check, a space would also get scrambled to
    /// a random glyph, ruining the word-boundary illusion. The original
    /// space stays put while non-space neighbours scramble around it.
    func replaceCharacter(at index: String.Index, character: Character) {
        guard animatedText.indices.contains(index) else { return }
        let indexCharacter = String(animatedText[index])

        if indexCharacter.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            animatedText.replaceSubrange(index ... index, with: String(character))
        }
    }
}

#Preview {
//    HackerTextView(text: "HackerTextView", trigger: true)
    HackerTextDemoView()
}
