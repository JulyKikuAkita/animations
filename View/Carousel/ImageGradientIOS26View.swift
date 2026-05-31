//
//  ImageGradientIOS26View.swift
//  animation
//
//  Created on 4/5/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Filename misleads — this file uses no iOS 26-only API. The
//        gradient pipeline is Core Image (`CIFilter.areaAverage`),
//        which works back to iOS 13. Consider dropping the `IOS26`
//        suffix, or adding an iOS 26 enhancement (e.g., `MeshGradient`)
//        to justify it.
//
//  Learning point
//  ──────────────
//  Builds an "ambient" full-screen gradient by SAMPLING the dominant
//  colours from a UIImage and stitching them into a vertical
//  LinearGradient. The image is split into N horizontal bands; each
//  band's average colour becomes one stop. Tap to cycle through the
//  bundled image set and watch the background recolour.
//
//  Pipeline:
//    1. Downsample the input UIImage so the average filter doesn't
//       chew through full-resolution pixels.
//    2. For each horizontal band, run `CIFilter.areaAverage` over
//       just that band's `extent`.
//    3. Read the 1×1 output pixel back as RGBA via `CIContext.render`.
//    4. Convert to `Color` and feed `LinearGradient(stops:)`.
//
//  Key APIs
//  ────────
//  • `CIFilter.areaAverage(inputImage:extent:)` — the sampler. One
//    call per band; cheap on downscaled inputs.
//  • `CIContext.render(_:toBitmap:rowBytes:bounds:format:colorSpace:)`
//    — pulls the 1×1 result back to CPU as `[UInt8]`.
//  • `LinearGradient(stops: [.init(color:location:)])` — the
//    SwiftUI side; one stop per band.
//  • `UIGraphicsImageRenderer` (in the downsample helper) — quick
//    way to scale a UIImage before sampling.
//
//  How to apply
//  ────────────
//  Reach for this when chrome should colour-match the displayed
//  artwork (album art, hero images). Watch the band count: 4–6 is
//  enough; more bands ≠ better, and `areaAverage` calls add up. For
//  the all-iOS 26 path, MeshGradient + 4 corner colours is even
//  cheaper.
//
//  See also
//  ────────
//  • View/PhotosView/CarouselImageWithAmbientBackgroundEffectView.swift
//    — alternative ambient-background trick using stacked blurred
//    copies of the image rather than colour sampling.
//
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ImageGradientDemoView: View {
    @State private var index: Int = 0

    var body: some View {
        ZStack {
            // Build a full-screen gradient from sampled colors in the current image.
            ImageGradient(
                image: UIImage(named: "IMG_020\(index)"),
                count: 10,
                animation: .smooth
            )
            .ignoresSafeArea()

            // Show the source image in the center so the sampled gradient can be compared directly.
            Image("IMG_020\(index)")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 250, height: 250)
                .clipShape(.rect(cornerRadius: 300))
        }
        .contentShape(.rect)
        .onTapGesture {
            // Cycle through the bundled demo images to preview different extracted palettes.
            index = (index + 1) % 10
        }
    }
}

struct ImageGradient: View {
    var image: UIImage?
    var count: Int = 3
    var animation: Animation? = .none

    var onFinished: ([Color]) -> Void = { _ in }

    /// The gradient starts with placeholder colors and is replaced once sampling finishes.
    @State private var colors: [Color] = [.blue, .brown]

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onAppear {
                guard let image else { return }
                updateFor(image: image)
            }
            .onChange(of: image) { _, newValue in
                guard let newImage = newValue else { return }
                updateFor(image: newImage)
            }
    }

    private func updateFor(image: UIImage) {
        // Sample from a downsized copy to keep Core Image work cheap while preserving the rough palette.
        let downsizedImage = downsize(image: image)
        let colors = extractColors(image: downsizedImage)
        debugPrint(colors)

        if let animation, !self.colors.isEmpty {
            withAnimation(animation) {
                self.colors = colors
            }
        } else {
            self.colors = colors
        }
        onFinished(colors)
    }

    /// Downsize to a small working image before sampling average colors.
    private func downsize(image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 200
        let imageSize = image.size
        let scale = maxDimension / max(imageSize.width, imageSize.height)
        let newSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        let renderFormat = UIGraphicsImageRendererFormat()
        renderFormat.scale = 1

        return UIGraphicsImageRenderer(size: newSize, format: renderFormat).image { _ in
            image.draw(in: .init(origin: .zero, size: newSize))
        }
    }

    /// Split the image into `count` horizontal bands and sample one representative color per band.
    /// The returned array is later fed directly into `LinearGradient`.
    private func extractColors(image: UIImage) -> [Color] {
        guard let ciImage = CIImage(image: image) else { return [] }

        let extent = ciImage.extent
        // Each loop iteration samples one horizontal slice of equal height.
        let titleHeight = extent.height / CGFloat(count)
        // Reuse a single Core Image context while rendering each 1x1 average-color result.
        let context = CIContext()

        var colors: [Color] = []

        for index in 0 ..< count {
            // Build the slice for this gradient stop.
            // We walk from the visual top of the image toward the bottom so the gradient colors match the image order.
            // Core Image coordinates start at the bottom-left, so the y-position has to be inverted manually.
            let cropRect = CGRect(
                x: extent.origin.x,
                y: extent.height - CGFloat(
                    index + 1
                ) * titleHeight,
                /// Do NOT use extent.origin.y + (titleHeight * CGFloat(index))
                /// as regular coordinates system that starts from the top left corner
                /// the core image starts from the bottom left corner,
                width: image.size.width,
                height: titleHeight
            )

            // `areaAverage` collapses the entire slice into a 1x1 image whose pixel is the average color.
            let filter = CIFilter.areaAverage()
            filter.inputImage = ciImage
            filter.extent = cropRect
            guard let outputImage = filter.outputImage else { continue }

            // Render that single pixel into RGBA bytes, then normalize 0...255 into SwiftUI color components.
            var bytes = [UInt8](repeating: 0, count: 4)
            context.render(
                outputImage,
                toBitmap: &bytes,
                rowBytes: 4,
                bounds: .init(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )

            let color = Color(
                red: CGFloat(bytes[0]) / 255,
                green: CGFloat(bytes[1]) / 255,
                blue: CGFloat(bytes[2]) / 255,
                opacity: CGFloat(bytes[3]) / 255
            )
            debugPrint("bytes: \(bytes)")
            debugPrint("color: \(color)")
            colors.append(color)
        }

        return colors
    }
}

#Preview {
    ImageGradientDemoView()
}
