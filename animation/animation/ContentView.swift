//
//  ContentView.swift
//  animation
//
//  Created by IFang Lee on 2/22/24.
//

import SwiftUI

struct ContentView: View {
    @State private var showView: Bool = false
    var body: some View {
        VStack {
            SourceView(id: "View 1") {
                Circle()
                    .fill(.red)
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        showView.toggle()
                    }
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showView, content: {
            DestinationView(id: "View 1") {
                Circle()
                    .fill(.red)
                    .frame(width: 150, height: 150)
                    .onTapGesture {
                        showView.toggle()
                    }
            }
            .padding(15)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .interactiveDismissDisabled() // animation effect requires to disable interaction such as go back or dismiss sheet
        })
        .heroLayer(id: "View 1", animate: $showView) {
            Circle()
                .fill(.red)
        } completion: { status in
            
        }
    }
}

#Preview {
    ContentView()
}
