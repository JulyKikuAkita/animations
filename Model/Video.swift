//
//  Video.swift
//  animation
import SwiftUI

struct Video: Identifiable, Hashable {
    var id: UUID = .init()
    var fileURL: URL
    var thumbnail: UIImage?
}

let files = [
    URL(filePath: Bundle.main.path(forResource: "Reel1", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel2", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel3", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel4", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel5", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel6", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel7", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel8", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel9", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel10", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel11", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel12", ofType: "mp4") ?? ""),
    URL(filePath: Bundle.main.path(forResource: "Reel13", ofType: "mp4") ?? "")

].compactMap({ Video(fileURL: $0) })
