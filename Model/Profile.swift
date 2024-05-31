//
//  Profile.swift
//  animation
//
//  Created by IFang Lee on 2/23/24.
//

import SwiftUI

struct Profile: Identifiable {
    var id = UUID()
    var username: String
    var profilePicture: String
    var lastMsg: String
    var lastActive: String
}

var profiles = [
Profile(username: "Kiku", profilePicture: "IMG_1504", lastMsg: "Woof", lastActive: "1:25 PM"),
Profile(username: "Hachi", profilePicture: "IMG_1915", lastMsg: "Wong", lastActive: "2:25 PM"),
Profile(username: "Akita", profilePicture: "IMG_2104", lastMsg: "Meow", lastActive: "3:25 PM"),
Profile(username: "Nanachi", profilePicture: "IMG_6162", lastMsg: "...", lastActive: "4:25 PM"),
Profile(username: "Banana", profilePicture: "IMG_8788", lastMsg: "banana", lastActive: "5:25 PM"),
Profile(username: "Fox", profilePicture: "fox", lastMsg: "Mr. Fox", lastActive: "8:25 PM"),
]

var stackCards = [
Profile(username: "", profilePicture: "", lastMsg: "", lastActive: ""), /// empty profile for StackedCards effect
Profile(username: "Fox", profilePicture: "fox", lastMsg: "Mr. Fox", lastActive: "8:25 PM"),
Profile(username: "Kiku", profilePicture: "IMG_1504", lastMsg: "Woof", lastActive: "1:25 PM"),
Profile(username: "Hachi", profilePicture: "IMG_1915", lastMsg: "Wong", lastActive: "2:25 PM"),
Profile(username: "Akita", profilePicture: "IMG_2104", lastMsg: "Meow", lastActive: "3:25 PM"),
Profile(username: "Nanachi", profilePicture: "IMG_6162", lastMsg: "...", lastActive: "4:25 PM"),
Profile(username: "Banana", profilePicture: "IMG_8788", lastMsg: "banana", lastActive: "5:25 PM"),
Profile(username: "Fox", profilePicture: "fox", lastMsg: "Mr. Fox", lastActive: "8:25 PM"),
]
