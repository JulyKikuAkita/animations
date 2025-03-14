//
//  MintTabs.swift
//  MyMint

import SwiftUI

enum MintTab: String {
    case recents = "Recents"
    case search = "Search"
    case charts = "Charts"
    case settings = "Settings"

    @ViewBuilder
    var tabContent: some View {
        switch self {
        case .recents:
            Image(systemName: "calendar")
            Text(rawValue)
        case .search:
            Image(systemName: "magnifyingglass")
            Text(rawValue)
        case .charts:
            Image(systemName: "chart.bar.xaxis")
            Text(rawValue)
        case .settings:
            Image(systemName: "gearshape")
            Text(rawValue)
        }
    }
}
