//
//  UIImage+Color.swift
//  animation
//  Convert Image to get the UIColor tone
/**
 if let image = UIImage(named: "your_image_asset") {
     let color: UIColor = image.averageColor()
     // Now you can use `color` as a UIColor
 }
 */

import UIKit

extension UIImage {
    func averageColor() -> UIColor? {
        guard let cgImage else {
            return nil
        }

        let width = 1
        let height = 1
        let bitmapData = calloc(width * height * 4, MemoryLayout<UInt8>.size)

        defer {
            free(bitmapData)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapContext = CGContext(
            data: bitmapData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        guard let context = bitmapContext else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = bitmapContext?.data else {
            return nil
        }

        let pixelData = data.bindMemory(to: UInt8.self, capacity: 4)

        // swiftlint:disable identifier_name
        let r = CGFloat(pixelData[0]) / 255.0
        let g = CGFloat(pixelData[1]) / 255.0
        let b = CGFloat(pixelData[2]) / 255.0
        let a = CGFloat(pixelData[3]) / 255.0
        // swiftlint:enable identifier_name

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
