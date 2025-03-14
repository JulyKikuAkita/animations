//
//  DocumentScannerAppApp.swift
//  DocumentScannerApp
//
//  Created by IFang Lee on 1/14/25.
//

import SwiftData
import SwiftUI

@main
struct DocumentScannerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Document.self)
        }
    }
}
