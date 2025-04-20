//
//  LocationPickerView.swift
//  animation
//
import CoreLocation
import MapKit
import SwiftUI

struct LocationPickerDemoView: View {
    @State private var showPicker: Bool = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    var body: some View {
        NavigationStack {
            List {
                Button("Pick a Location") {
                    showPicker.toggle()
                }
                .locationPicker(isPresented: $showPicker) { coordinate in
                    if let coordinate {
                        selectedLocation = coordinate
                    }
                }

                if let selectedLocation {
                    Text("Selected Location: \(selectedLocation)")
                }
            }
            .navigationTitle("Custom Location Picker")
        }
    }
}

extension View {
    func locationPicker(isPresented: Binding<Bool>, coordinates: @escaping (CLLocationCoordinate2D?) -> Void) -> some View {
        fullScreenCover(isPresented: isPresented) {
            LocationPickerView(isPresented: isPresented, coordinate: coordinates)
        }
    }
}

#Preview {
    LocationPickerDemoView()
}
