//
//  Contact.swift
//  animation
//
import SwiftUI

struct Contact: Identifiable {
    var id: String = UUID().uuidString
    let name: String
    let email: String
}

let dummyContacts: [Contact] = [
    Contact(name: "Avatar", email: "avatar@example.com"),
    Contact(name: "Argo", email: "2012@oscar.com"),
    Contact(name: "Braveheart", email: "1995@oscar.com"),
    Contact(name: "Casablanca", email: "avatar@example.com"),
    Contact(name: "Chicago", email: "2002@oscar.com"),
    Contact(name: "Django Unchained", email: "avatar@example.com"),
    Contact(name: "The Departed", email: "2006@oscar.com"),
    Contact(name: "E.T. the Extra-Terrestrial", email: "avatar@example.com"),
    Contact(name: "Everything Everywhere All at Once", email: "2022@oscar.com"),
    Contact(name: "Forrest Gump", email: "1994@oscar.com"),
    Contact(name: "Gladiator", email: "2000@oscar.com"),
    Contact(name: "Hamlet", email: "1948@oscar.com"),
    Contact(name: "Harry Potter and the Sorcerer's Stone", email: "avatar@example.com"),
    Contact(name: "In the Heat of the Night", email: "1967@oscar.com"),
    Contact(name: "Inception", email: "avatar@example.com"),
    Contact(name: "Jurassic Park", email: "avatar@example.com"),
    Contact(name: "The King's Speech", email: "2010@oscar.com"),
    Contact(name: "Kill Bill: Vol. 1", email: "avatar@example.com"),
    Contact(name: "Lord of the Rings: The Fellowship of the Ring", email: "avatar@example.com"),
    Contact(name: "The Last Emperor", email: "1987@oscar.com"),
    Contact(name: "Moonlight", email: "2016@oscar.com"),
    Contact(name: "Mad Max: Fury Road", email: "avatar@example.com"),
    Contact(name: "No Country for Old Men", email: "2007@oscar.com"),
    Contact(name: "Oppenheimer", email: "avatar@example.com"),
    Contact(name: "Oliver!", email: "1968@oscar.com"),
    Contact(name: "Parasite", email: "2019@oscar.com"),
    Contact(name: "Pulp Fiction", email: "avatar@example.com"),
    Contact(name: "Quantum of Solace", email: "avatar@example.com"),
    Contact(name: "The Queen", email: "xxxx@oscar.com"),
    Contact(name: "Raiders of the Lost Ark", email: "avatar@example.com"),
    Contact(name: "Rain Man", email: "1988@oscar.com"),
    Contact(name: "Spider-Man: No Way Home", email: "avatar@example.com"),
    Contact(name: "Schindler’s List", email: "1993@oscar.com"),
    Contact(name: "Titanic", email: "1997@oscar.com"),
    Contact(name: "Unforgiven", email: "1992@oscar.com"),
    Contact(name: "Up", email: "avatar@example.com"),
    Contact(name: "V for Vendetta", email: "avatar@example.com"),
    Contact(name: "The Verdict", email: "2007@oscar.com"),
    Contact(name: "West Side Story", email: "1961@oscar.com"),
    Contact(name: "Wolf of Wall Street", email: "avatar@example.com"),
    Contact(name: "X-Men", email: "avatar@example.com"),
    Contact(name: "You've Got Mail", email: "avatar@example.com"),
    Contact(name: "You Can’t Take It with You", email: "1938@oscar.com"),
    Contact(name: "The Ziegfeld Follies", email: "avatar@example.com"),
    Contact(name: "Zootopia", email: "avatar@example.com"),
]
