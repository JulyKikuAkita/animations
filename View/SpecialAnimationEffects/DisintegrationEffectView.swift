//
//  DisintegrationEffectView.swift
//  animation
//
//  Learning point
//  ──────────────
//  "Thanos snap" / Marvel-style disintegration effect: a SwiftUI view
//  appears to crumble into hundreds of tiny particles that drift up
//  and to the left as they fade out. Apply via the file-local
//  modifier:
//
//      myView.disintegrationEffect(isDeleted: $flag) {
//          // completion: actually remove the view from the layout
//      }
//
//  How the effect works (recipe)
//  ─────────────────────────────
//    1. **Snapshot the source view** — `.snapshot(trigger:)` (project
//       helper using `ImageRenderer`) captures the rendered
//       `UIImage` once `isDeleted` flips.
//    2. **Crop into a grid of square tiles** — auto-pick `gridSize`
//       so total tile count stays ≤ 1100 (memory + perf bound).
//       Each tile becomes a `SnapParticle` with its original (x, y)
//       offset and a tiny cropped image.
//    3. **Hide the original, show the particles** — the modifier
//       sets `content.opacity(0)` once particles are populated, then
//       overlays the particle stack at the same position.
//    4. **Animate every particle by random offset + opacity 0** —
//       each particle slides to a `(-60..-10, -100..-10)` random
//       offset over 1.5s, with a 5pt blur for cohesion. Once the
//       animation completes, the `.completion` callback fires so the
//       caller can remove the view from layout.
//
//  Why ≤ 1600 particles? Because each particle is its own SwiftUI
//  `Image` view + offsets + opacity, and the renderer slows
//  noticeably past that count even on modern devices. 1100 is a
//  safe ceiling for typical button / image sizes.
//
//  Why NOT navigation stacks / scroll views?
//  ─────────────────────────────────────────
//  Snapshots capture the rendered output of *one frame*; if the
//  source view scrolls, paginates, or contains dynamic dependent
//  layout, the snapshot freezes that state and the disintegration
//  looks visually wrong (clipped scroll content, missing nav bar).
//
//  Why `.compositingGroup() + .blur(radius: 5)` on the particle stack
//  ──────────────────────────────────────────────────────────────────
//  Blurring all particles together (after compositingGroup flattens
//  them into one layer) is much cheaper than blurring each one. The
//  5pt blur also visually "fuses" particles that overlap, hiding
//  the grid origin and making the dust feel more organic.
//
//  Why `Task.detached(priority: .high)` for particle creation
//  ─────────────────────────────────────────────────────────
//  Cropping ~1100 sub-images is CPU work; doing it on the main
//  actor would freeze the UI. Detach to a background priority,
//  then `await MainActor.run` to commit the result. The 0.2s
//  initial sleep gives the SwiftUI snapshot pipeline time to
//  finish rendering.
//
//  Key APIs
//  ────────
//  • `.snapshot(trigger:)` (project helper) — view-as-UIImage.
//  • `UIGraphicsImageRenderer` + `ctx.cgContext.interpolationQuality = .low`
//    — fast cropping; particles will fade out anyway, so high
//    quality is wasted.
//  • `withAnimation(_, completionCriteria: .logicallyComplete) { ... } completion:` —
//    iOS 17+; fires once the *visual* animation completes.
//  • `Task.detached(priority: .high)` — heavy work off the main actor.
//
//  How to apply
//  ────────────
//  Use sparingly for "delete with style" moments — favourites
//  removal, message deletion, tap-to-dismiss confirmations. The
//  snapshot+grid+animate-each-tile recipe generalises to any
//  particle decomposition (page tear, fragmentation explosion).
//

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

private struct DisintegrationEffectView: View {
    @Binding var particles: [SnapParticle]
    @Binding var animateEffect: Bool
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(particles) { particle in
                Image(uiImage: particle.particleImage)
                    .offset(particle.particleOffset)
                    .offset(
                        x: animateEffect ? .random(in: -60 ... -10) : 0,
                        y: animateEffect ? .random(in: -100 ... -10) : 0
                    )
                    .opacity(animateEffect ? 0 : 1)
            }
        }
        .compositingGroup()
        .blur(radius: animateEffect ? 5 : 0) /// apply blur effect to the whole view to save memory usage
    }
}

private struct DisintegrationEffectModifier: ViewModifier {
    var isDeleted: Bool
    var completion: () -> Void
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
            .onChange(of: isDeleted) { _, newValue in /// prevent create multiple snapshots
                if newValue, particles.isEmpty {
                    triggerSnapshot = true
                }
            }
    }

    private func createParticles(_ snapshot: UIImage) async {
        var particles: [SnapParticle] = []
        let size = snapshot.size
        let width = size.width
        let height = size.height
        let maxGridCount = 1100 /// up to 1600 is not recommended

        // Tip: auto-tune grid size to cap total particle count.
        // Start at 1×1 tiles and grow until rows*columns drops below
        // maxGridCount (1100). Larger source images get coarser tiles
        // — keeps memory bounded regardless of view size.
        var gridSize = 1
        var rows = Int(height) / gridSize
        var columns = Int(width) / gridSize

        while (rows * columns) >= maxGridCount {
            gridSize += 1
            rows = Int(height) / gridSize
            columns = Int(width) / gridSize
        }

        for row in 0 ... rows {
            for column in 0 ... columns {
                let positionX = column * gridSize
                let positionY = row * gridSize

                let cropRect = CGRect(x: positionX, y: positionY, width: gridSize, height: gridSize)
                let croppedImage = cropImage(snapshot, rect: cropRect)
                particles.append(.init(
                    particleImage: croppedImage,
                    particleOffset: .init(width: positionX, height: positionY)
                )
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

private struct SnapParticle: Identifiable {
    var id: String = UUID().uuidString
    var particleImage: UIImage
    var particleOffset: CGSize
}

extension View {
    @ViewBuilder
    func disintegrationEffect(isDeleted: Bool, completion: @escaping () -> Void) -> some View {
        modifier(DisintegrationEffectModifier(isDeleted: isDeleted, completion: completion))
    }
}

#Preview {
    DisintegrationEffectDemoView()
}
