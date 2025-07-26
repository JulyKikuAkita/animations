//
//  Permission.swift
//  animation

import AVKit
import CoreLocation
import PhotosUI
import SwiftUI

enum Permission: String, CaseIterable {
    case location = "Location Service"
    case camera = "Camera Access"
    case microPhone = "Microphone Access"
    case photoLibrary = "Photo Library Access"

    var symbol: String {
        switch self {
        case .location:
            "location.fill"
        case .camera:
            "camera.fill"
        case .microPhone:
            "microhone.fill"
        case .photoLibrary:
            "photo.stack.fill"
        }
    }

    var orderedIndex: Int {
        switch self {
        case .camera: 0
        case .microPhone: 1
        case .photoLibrary: 2
        case .location: 3
        }
    }

    var isGranted: Bool? {
        switch self {
        case .location:
            let status = CLLocationManager().authorizationStatus
            return status == .notDetermined ? nil : status == .authorizedAlways || status == .authorizedWhenInUse
        case .camera:
            let staus = AVCaptureDevice.authorizationStatus(for: .video)
            return staus == .notDetermined ? nil : staus == .authorized
        case .microPhone:
            let staus = AVCaptureDevice.authorizationStatus(for: .audio)
            return staus == .notDetermined ? nil : staus == .authorized
        case .photoLibrary:
            let staus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return staus == .notDetermined ? nil : staus == .authorized || staus == .limited
        }
    }
}
