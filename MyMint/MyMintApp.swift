//
//  MyMintApp.swift
//  MyMint
//
//  Created by IFang Lee on 5/14/24.
//

import SwiftUI

@main
struct MyMintApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Transaction.self]) /// missing this line  will crash app
    }
}
