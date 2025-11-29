//
//  MapModels.swift
//  animation
//
//  Created on 11/29/25.

import MapKit
import SwiftUI

struct Place: Identifiable {
    var id: Int
    var name: String
    var location: CLLocationCoordinate2D
    var mapItem: MKMapItem
}
