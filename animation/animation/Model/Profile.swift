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
}

var profiles = [
Profile(username: "Kiku", profilePicture: "IMG_1504", lastMsg: "Woof"),
Profile(username: "Hachi", profilePicture: "IMG_1915", lastMsg: "Wong"),
Profile(username: "Akita", profilePicture: "IMG_2104", lastMsg: "Meow"),
Profile(username: "Nanachi", profilePicture: "IMG_6162", lastMsg: "..."),
Profile(username: "Banana", profilePicture: "IMG_8788", lastMsg: "banana")
]
