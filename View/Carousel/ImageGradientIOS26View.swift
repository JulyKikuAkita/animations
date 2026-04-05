//
//  ImageGradientIOS26View.swift
//  animation
//
//  Created on 4/5/26.

import CoreImage.CIFilterBuiltins
import SwiftUI

struct ImageGradientDemoView: View {
    @State private var index: Int = 0
    var body: some View {
        ZStack {
            ImageGradient(
                image: UIImage(named: "IMG_020\(index)"),
                count: 10,
                animation: .smooth
            )
            .ignoresSafeArea()

            Image("IMG_020\(index)")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 250, height: 250)
                .clipShape(.rect(cornerRadius: 300))
        }
        .contentShape(.rect)
        .onTapGesture {
            index = (index + 1) % 10
        }
    }
}

struct ImageGradient: View {
    var image: UIImage?
    var count: Int = 3
    var animation: Animation? = .none

    var onFinished: ([Color]) -> Void = { _ in }
    /// View properties
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

    /// Downsizing Image to <= 200 max dimension
    ///  use it to identiy the dominant color for gradient background  with CIFilter(averageArea)
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

    /// Extracting Dominant Colors
    private func extractColors(image: UIImage) -> [Color] {
        guard let ciImage = CIImage(image: image) else { return [] }

        let extent = ciImage.extent
        let titleHeight = extent.height / CGFloat(count)
        let context = CIContext()

        var colors: [Color] = []

        for index in 0 ..< count {
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

            let filter = CIFilter.areaAverage()
            filter.inputImage = ciImage
            filter.extent = cropRect
            guard let outputImage = filter.outputImage else { continue }

            /// Extracting Color
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
