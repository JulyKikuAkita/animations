//
//  SliderWorkaroundScrollView.swift
//  animation

import SwiftUI

struct SliderWorkaroundScrollDemoView: View {
    @State private var isScrollDisabled: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Volume")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    
                    Text(isScrollDisabled ? "Scroll Disabled" : "Scroll Enabled")
                    
                    VolumeSliderWithSimultaneousGesture(isScrollDisabled: $isScrollDisabled)
                }
                .padding()
            }
            .scrollDisabled(isScrollDisabled)
            .navigationTitle("Gesture - iOS 18")
        }
    }
}

/// fix 1. use DragGesture(minimumDistance: 30)
struct VolumeSlider: View {
    @Binding var isScrollDisabled: Bool
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                Rectangle()
                    .fill(.black)
                    .frame(width: progress * size.width)
            }
            .clipShape(.rect(cornerRadius: 10))
            .gesture(
                DragGesture(minimumDistance: 30) /// fix 1: increase translation value from default 10 to 30
                    .onChanged { value in
                        let progress = (value.translation.width / size.width) + lastProgress
                        self.progress = max(min(progress, 1), 0)
                    }.onEnded { _ in
                        lastProgress = progress
                    }
            )
        }
        .frame(height: 40)
    }
}

/// iOS 18 only
/// fix 2: use simultaneousGesture
struct VolumeSliderWithSimultaneousGesture: View {
    @Binding var isScrollDisabled: Bool
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0
    @State private var velocity: CGSize = .zero /// help identity  scroll or slider gesture
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                Rectangle()
                    .fill(.black)
                    .frame(width: progress * size.width)
            }
            .clipShape(.rect(cornerRadius: 10))
            .simultaneousGesture(
                customGesture
                    .onChanged { value in
                        if #available(iOS 18, *) {
                            if velocity == .zero {
                                velocity = value.velocity
                            }
                            
                            guard velocity.height == 0 else { return }
                            isScrollDisabled = true
                        }
                        let progress = (value.translation.width / size.width) + lastProgress
                        self.progress = max(min(progress, 1), 0)
                    }.onEnded { _ in
                        lastProgress = progress
                        if #available(iOS 18, *) {
                            velocity = .zero
                            isScrollDisabled = false
                        }
                    }
            )
        }
        .frame(height: 40)
    }
    
    var customGesture: DragGesture {
        if #available(iOS 18, *) {
            DragGesture(minimumDistance: 1) /// don't use 0 otherwise won't trigger when we  touch it
        } else {
            DragGesture()
        }
    }
}

/// only in iOS 18 (not seen in iOS 17)
/// Volume slider does not allow scroll interaction (not able to pull up/down)
struct VolumeSliderWithIssue: View {
    @Binding var isScrollDisabled: Bool
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                Rectangle()
                    .fill(.black)
                    .frame(width: progress * size.width)
            }
            .clipShape(.rect(cornerRadius: 10))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let progress = (value.translation.width / size.width) + lastProgress
                        self.progress = max(min(progress, 1), 0)
                    }.onEnded { _ in
                        lastProgress = progress
                    }
            )
        }
        .frame(height: 40)
    }
}



#Preview {
    SliderWorkaroundScrollDemoView()
}
