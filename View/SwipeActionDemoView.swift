//
//  SwipeActionDemoView.swift
//  animation

import SwiftUI

struct SwipeActionDemoView: View {
    var body: some View {
        NavigationStack {
            SwipeActionHomeView()
                .navigationTitle("Messages")
        }
    }
}

struct SwipeActionHomeView: View {
    /// Sample array of colors
    @State private var colors: [Color] = [.black, .yellow, .purple, .brown]
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    CardView(color)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    /// Sample card view
    @ViewBuilder
    func CardView(_ color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 6, content: {
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 80, height: 5)
                
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 60, height: 5)
            })
            
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.4))
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(color.gradient)

    }
}

/// Custom swipe action view
struct SwipeAction<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollViewReader { scrollProxy in /// reset scroll view to original position  when swipe action is pressed
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    content
                        /// to take full available space
                        .containerRelativeFrame(.horizontal)
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned) /// ViewAligned scroll target behavior requires scrollTargetLayout() to be added inside the scrollView
        }
    }
}

// TODO: https://www.youtube.com/watch?v=K8VnH2eEnK4&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=53
// 3:00
#Preview {
    SwipeActionDemoView()
}
