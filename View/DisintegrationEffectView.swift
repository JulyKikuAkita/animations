//
//  DisintegrationEffectView.swift
//  animation
// suitable for buttons, texts, images, message bubbles
// Not for navigation stacks or scroll views
// Lower particle counts work better (and not exceed 1600)

import SwiftUI

struct DisintegrationEffectDemoView: View {
    @State private var snapEffect: Bool = false
    @State private var isRemoved: Bool = false
    var body: some View {
        NavigationStack {
            VStack {
                if !isRemoved {
                    Group {
                        Image(.fox)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .disintegrationEffect(isDeleted: snapEffect) {
                                withAnimation(.snappy) {
                                    isRemoved = true
                                }
                            }

                        Button("Remove View") {
                            snapEffect = true
                        }
                    }
                }
            }
            .navigationTitle("Disintegration Effect")
        }
    }
}

fileprivate struct DisintegrationEffectView: View {
    @Binding var particles: [SnapParticle]
    @Binding var animateEffect: Bool
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(particles) { particle in
                Image(uiImage: particle.particleImage)
                    .offset(particle.particleOffset)
                    .offset(
                        x: animateEffect ? .random(in: -60...(-10)) : 0,
                        y: animateEffect ? .random(in: -100...(-10)) : 0
                    )
                    .opacity(animateEffect ? 0 : 1)
            }
        }
        .compositingGroup()
        .blur(radius: animateEffect ? 5 : 0) /// apply blur effect to the whole view to save memory usage
    }
}

fileprivate struct DisintegrationEffectModifier: ViewModifier {
    var isDeleted: Bool
    var completion: () -> ()
    /// View Properties
    @State private var particles: [SnapParticle] = []
    @State private var animateEffect: Bool = false
    @State private var triggerSnapshot: Bool = false

    func body(content: Content) -> some View {
        content
            .opacity(particles.isEmpty ? 1 : 0)
            .overlay(alignment: .topLeading) {
                DisintegrationEffectView(particles: $particles, animateEffect: $animateEffect)
            }
            .snapshot(trigger: triggerSnapshot) { snapshot in
                Task.detached(priority: .high) {
                    try? await Task.sleep(for: .seconds(0.2))
                    await createParticles(snapshot)
                }
            }
            .onChange(of: isDeleted) { oldValue, newValue in /// prevent create multiple snapshots
                if newValue && particles.isEmpty {
                    triggerSnapshot = true
                }
            }
    }

    private func createParticles(_ snapshot: UIImage) async {
        var particles: [SnapParticle] = []
        let size = snapshot.size
        let width = size.width
        let height = size.height
        let maxGridCount: Int = 1100 /// up to 1600 is not recommended

        var gridSize: Int = 1
        var rows = Int(height) / gridSize
        var columns = Int(width) / gridSize


        while (rows * columns) >= maxGridCount {
            gridSize += 1
            rows = Int(height) / gridSize
            columns = Int(width) / gridSize
        }

        for row in 0...rows {
            for column in 0...columns {
                let positionX = column * gridSize
                let positionY = row * gridSize

                let cropRect = CGRect(x: positionX, y: positionY, width: gridSize, height: gridSize)
                let croppedImage = cropImage(snapshot, rect: cropRect)
                particles.append(.init(
                    particleImage: croppedImage,
                    particleOffset: .init(width: positionX, height: positionY
                    ))
                )
            }
        }

        await MainActor.run { [particles] in
            self.particles = particles
            withAnimation(.easeInOut(duration: 1.5), completionCriteria: .logicallyComplete) {
                animateEffect = true
            } completion: {
                completion()
            }
        }
    }

    /// crop snapshot image to match particle size and origin
    /// use the lowest quality image as it's going to dis integrate and fade out
    private func cropImage(_ snapshot: UIImage, rect: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .low
            snapshot.draw(at: .init(x: -rect.origin.x, y: -rect.origin.y))

        }

    }
}

fileprivate struct SnapParticle: Identifiable {
    var id: String = UUID().uuidString
    var particleImage: UIImage
    var particleOffset: CGSize
}


extension View {
    @ViewBuilder
    func disintegrationEffect(isDeleted: Bool, completion: @escaping () -> ()) -> some View {
        self
            .modifier(DisintegrationEffectModifier(isDeleted: isDeleted, completion: completion))
    }
}


#Preview {
    DisintegrationEffectDemoView()
}
