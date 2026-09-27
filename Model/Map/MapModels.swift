//
//  MapModels.swift
//  animation
//
//  Created on 11/29/25.

import MapKit
import SwiftUI

struct Place: Identifiable {
    var id: UUID = .init()
    var name: String
    var coordinates: CLLocationCoordinate2D
    var mapItem: MKMapItem

    var address: String {
        if #available(iOS 26.0, *) {
            mapItem.address?.fullAddress ?? "N/A"
        } else {
            mapItem.placemark.title ?? "N/A"
        }
    }

    var phoneNumber: String? {
        mapItem.phoneNumber
    }
}

public extension MKCoordinateRegion {
    /// Apple Park Location Coordinates
    static var applePark: MKCoordinateRegion {
        .init(
            center: .init(
                latitude: 37.3346,
                longitude: -122.0090
            ),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    }

    static var applePark250K: MKCoordinateRegion {
        .init(
            center: .init(
                latitude: 37.3346,
                longitude: -122.0090
            ),
            latitudinalMeters: 250_000,
            longitudinalMeters: 250_000
        )
    }
}

protocol VerticalItem: CaseIterable, Hashable {
    var symbol: String { get }
}

enum MapMode: String, VerticalItem {
    case explore = "Explore"
    case driving = "Driving"
    case satellite = "Satellite"

    var symbol: String {
        switch self {
        case .explore: "map.fill"
        case .driving: "car.fill"
        case .satellite: "globe.americas.fill"
        }
    }
}
