//
//  TodoView.swift
//  animation
//
//  Created by IFang Lee on 3/29/24.
//

import SwiftUI
import SwiftData

struct TodoView: View {
    var body: some View {
        NavigationStack {
            Home()
                .navigationTitle("Todo List")
        }
    }
}

struct Home: View {
    var body: some View {
        Text("Hello, World!")
    }
}
#Preview {
    ContentView()
}
