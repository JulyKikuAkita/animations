//
//  LocationPickerView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cross-folder cleanup
//        The actual `LocationPickerView` struct is defined in
//        `Helpers/CoreLocation/LocationPickerManager.swift` —
//        filename says "Manager" but the file contains a "View".
//        Either rename that file to `LocationPickerView.swift`
//        (then this demo file probably needs a different name) or
//        move the helper struct out of "Manager.swift". Surfacing
//        here because the cross-folder name confusion is what makes
//        the call site here read oddly.
//
//  Learning point
//  ──────────────
//  Thin demo wrapper that exposes a one-line API for "show me a
//  full-screen map and call back with the picked coordinate":
//
//      .locationPicker(isPresented: $showPicker) { coord in ... }
//
//  The demo itself is trivial — it just toggles the binding and
//  prints the result. The interesting code is in the helper file
//  (`Helpers/CoreLocation/LocationPickerManager.swift`), which owns
//  the `LocationPickerView` View, the `LocationManager`
//  `@StateObject`, search results, permission gating, and the
//  matched-namespace map transition.
//
//  This file's main contribution is the `View.locationPicker(...)`
//  extension — the public-facing call shape. Keep it stable; the
//  helper file is the implementation detail callers shouldn't have
//  to know about.
//
//  Key APIs
//  ────────
//  • `View.locationPicker(isPresented:coordinates:)` — the public
//    extension defined here.
//  • `fullScreenCover(isPresented:)` — the underlying presentation.
//  • `CLLocationCoordinate2D` — Core Location's coordinate type;
//    surfaced as the result.
//
//  How to apply
//  ────────────
//  Call `.locationPicker(...)` on any view that needs a one-shot
//  coordinate selection (delivery address, meet-up point, photo
//  geo-tag). For full permission-prompt onboarding before showing
//  the map, see [[LocationPermissionFullSheetView]].
//
//  See also
//  ────────
//  • Helpers/CoreLocation/LocationPickerManager.swift — the actual
//    `LocationPickerView` implementation.
//  • View/Map/View/CustomMapView.swift — heavier map demo with a
//    bottom carousel of nearby places.
//  • View/Map/View/LocationPermissionFullSheetView.swift —
//    permission flow that pairs with this picker.
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
