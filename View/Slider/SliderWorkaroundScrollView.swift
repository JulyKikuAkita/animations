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
                    
                    VolumeSlider(isScrollDisabled: $isScrollDisabled)
                }
                .padding()
            }
            .scrollDisabled(isScrollDisabled)
            .navigationTitle("Gesture - iOS 18")
        }
    }
}

// https://www.youtube.com/watch?v=9W7rp_jtW4Q&t=19s 1:23
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
                DragGesture()
                    .onChanged { value in
                        let progress = ((value.translation.width / size.width) + lastProgress
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
    SliderWorkaroundScrollView()
}
