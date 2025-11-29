//
//  CustomMapView.swift
//  animation
//
//  Created on 11/29/25.

import MapKit
import SwiftUI

struct CustomMapView: View {
    /// View Properties
    @State private var cameraPosition: MapCameraPosition
    @State private var places: [Place] = []
    /// Environment Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        NavigationStack {}
    }
}
