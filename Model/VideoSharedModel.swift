//
//  VideoSharedModel.swift
//  animation

import SwiftUI
import AVKit

@Observable
class VideoSharedModel {
    var videos: [Video] = files
    
    func generateThumbnail(_ video: Binding<Video>, size: CGSize) async {
        do {
            let asset = AVURLAsset(url: video.wrappedValue.fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.maximumSize = size
            generator.appliesPreferredTrackTransform = true
            
            // Generate thumbnail from video URL at 0 seconds
            // update .zero to a different time as needed
            let cgImage = try await generator.image(at: .zero).image
            guard let deviceColorBasedImage = cgImage.copy(
                colorSpace: CGColorSpaceCreateDeviceRGB()
            ) else { return }
            
            let thumbnail = UIImage(cgImage: deviceColorBasedImage)
            await MainActor.run {
                video.wrappedValue.thumbnail = thumbnail
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
