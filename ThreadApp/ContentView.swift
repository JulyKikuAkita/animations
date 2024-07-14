//
//  ContentView.swift
//  ThreadApp
//
//  Created by IFang Lee on 7/6/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SynchronizedScrollView()
        }
    }
}

#Preview {
    ContentView()
}
