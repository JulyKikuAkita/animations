//
//  HackerTextView.swift
//  animation

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

    private func animateText() {
        let currentID = animationID
        for index in text.indices {
            let delay = CGFloat.random(in: 0 ... duration)
            var timerDuration: CGFloat = 0

            let timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
                if currentID != animationID {
                    timer.invalidate()
                } else {
                    timerDuration += speed
                    if timerDuration >= delay {
                        if text.indices.contains(index) {
                            let actualCharacter = text[index]
                            replaceCharacter(at: index, character: actualCharacter)
                        }

                        timer.invalidate()
                    } else {
                        guard let randomCharacter = randomCharacters.randomElement() else { return }
                        replaceCharacter(at: index, character: randomCharacter)
                    }
                }
            }
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

    /// Change character at the given index
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
