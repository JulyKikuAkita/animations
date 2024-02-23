//
//  ContentView.swift
//  animation
//
//  Created by IFang Lee on 2/22/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    CardView(item: item)
                }
            }
            .navigationTitle("Hero Effect")
        }
    }
}

struct CardView: View {
    var item: Item
    /// View properties
    @State private var expandSheet: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            SourceView(id: item.id.uuidString) {
                ImageView()
            }
            
            Text(item.title)
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .onTapGesture {
            expandSheet.toggle()
        }
        
        .sheet(isPresented: $expandSheet, content: {
            DestinationView(id: item.id.uuidString) {
                ImageView()
                    .onTapGesture {
                        expandSheet.toggle()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding()
        })
        .heroLayer(id: item.id.uuidString,
                   animate: $expandSheet) {
            ImageView()
        }  completion: { _ in
            
        }
    }
    
    @ViewBuilder
    func ImageView() -> some View {
        Image(systemName: item.symbol)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(item.color.gradient, in: .circle)
    }
}

struct DemoView: View {
    @State private var showView: Bool = false
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Navigation Style")
            .navigationDestination(isPresented: $showView) {
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
                .navigationBarBackButtonHidden() // animation effect requires to disable interaction such as go back
                .navigationTitle("Detail View")
            }
        }
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


/// Demo Item Model

struct Item: Identifiable {
    var id: UUID = .init()
    var title: String
    var color: Color
    var symbol: String
}

var items: [Item] = [
    .init(title: "Book Icon", color: .red, symbol: "book.fill"),
    .init(title: "Stack Icon", color: .blue, symbol: "square.stack.3d.up"),
    .init(title: "Rectangle Icon", color: .orange, symbol: "rectangle.portrait")
]
