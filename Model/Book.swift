//
//  Book.swift
//  animation
import SwiftUI

struct Book: Identifiable {
    let id: String = UUID().uuidString
    let title: String
    let author: String
    let rating: String
    let thumbnail: String
    let ISBN: String
    let color: Color
}

let dummyBooks: [Book] = [
    .init(
        title: "The Hitchhiker's Guide to the Galaxy",
        author: "Douglas Adams",
        rating: "4.8 (32) * Science Fiction",
        thumbnail: "fox",
        ISBN: "0-330-25864-8",
        color: .indigo
    ),
    .init(
        title: "Life, the Universe and Everything",
        author: "Douglas Adams",
        rating: "4.5 (2) * Science fiction comedy",
        thumbnail: "IMG_0204",
        ISBN: "0-345-39182-9",
        color: .pink
    )
]

let paragraph1 = """
The conversation between Deep Thought and the prophets/priests after Deep Thought spends millions of years calculating the Answer to the Question of Life, the Universe, and Everything. Deep Thought awakens after millions of years of cogitation. The prophets/priests (descendants of the programmers) and millions of others are waiting for the Answer. Deep Thought comes to life and the prophets ask, “Deep Thought, do you know the Answer to the Question of Life, the Universe, and Everything?”
“Yes.”
“And can you tell us the Answer to the Question of Life, the Universe, and Everything?”
“Yes.”
“Tell us the Answer to the Question of Life, the Universe, and Everything?”
“You’re not going to like it.”
“Tell us!”
“You’re really not going to like it.”
“TELL US!”
“42”
“What the !@@$?”
“I told you you weren’t going to like it.”"
"""

let paragraph2 = """
“It comes from a very ancient democracy, you see..."
"You mean, it comes from a world of lizards?"
"No," said Ford, who by this time was a little more rational and coherent than he had been, having finally had the coffee forced down him, "nothing so simple. Nothing anything like so straightforward. On its world, the people are people. The leaders are lizards. The people hate the lizards and the lizards rule the people."
"Odd," said Arthur, "I thought you said it was a democracy."
"I did," said Ford. "It is."
"So," said Arthur, hoping he wasn't sounding ridiculously obtuse, "why don't people get rid of the lizards?"
"It honestly doesn't occur to them," said Ford. "They've all got the vote, so they all pretty much assume that the government they've voted in more or less approximates to the government they want."
"You mean they actually vote for the lizards?"
"Oh yes," said Ford with a shrug, "of course."
"But," said Arthur, going for the big one again, "why?"
"Because if they didn't vote for a lizard," said Ford, "the wrong lizard might get in. Got any gin?"
"""
