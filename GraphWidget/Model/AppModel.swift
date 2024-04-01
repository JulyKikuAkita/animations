//
//  AppModel.swift
//  animation

import SwiftUI

/// App consists of last 7 days of data
struct AppModel: Identifiable {
    var id: String
    var appName: String
    var appDownloads: [Downloads]
}

/// keep 3 items to best view in widgets; the id will be show at segment control
let apps: [AppModel] = [
    .init(id: "App 1", appName: "App 1 Name", appDownloads: appDownloads),
    .init(id: "App 2", appName: "App 2 Name", appDownloads: appDownloads1),
    .init(id: "App 3", appName: "App 3 Name", appDownloads: appDownloads2),
]
