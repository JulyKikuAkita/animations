//
//  LocationPicker.swift
//  animation

import CoreLocation
import MapKit
import SwiftUI

struct LocationPickerDemoView: View {
    @State private var showPicker: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Pick a Location") {
                    showPicker.toggle()
                }
                .locationPicker(isPresented: $showPicker) { _ in
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

struct LocationPicker: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

private struct LocationPickerView: View {
    @Binding var isPresented: Bool
    var coordinate: (CLLocationCoordinate2D?) -> Void
    /// View Properties
    @StateObject private var manager: LocationManager = .init()
    /// Environment Properties
    @Namespace private var mapSpace
    @Environment(\.openURL) var openURL
    var body: some View {
        ZStack {
            if let isPermissionDenied = manager.isPermissionDenied {
                if isPermissionDenied {
                    NoPermissionView()
                } else {
                    MapView()
                }
            } else {
                Group {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()

                    ProgressView()
                }
            }
        }
        .onAppear(perform: manager.requestUserLocation)
    }

    func mapSearchBar() -> some View {
        VStack(spacing: 15) {
            Text("Select Location")
                .fontWeight(.semibold)
        }
    }

    func mapView() -> some View {
        Map(position: $manager.position) {
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton(scope: mapSpace)
            MapCompass(scope: mapSpace)
            MapPitchToggle(scope: mapSpace)
        }
        .mapScope(mapSpace)
    }

    func noPermissionView() -> some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Text("Please allow location permission\nin the app settings!")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(15)
                    .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            /// Try again and go to settings buttions
            VStack(spacing: 11) {
                Button("Try Again", action: manager.requestUserLocation)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Button {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
                    }
                } label: {
                    Text("Go to Settings")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.background)
                        .background(.primary, in: .rect(cornerRadius: 12))
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
            }
        }
    }
}

// Data for location manager
private class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isPermissionDenied: Bool?
    /// Map Properties
    @Published var currentRegion: MKCoordinateRegion?
    @Published var position: MapCameraPosition = .automatic
    @Published var userCoordinate: CLLocationCoordinate2D?

    private var manager: CLLocationManager = .init()
    override init() {
        super.init()
        manager.delegate = self
    }

    /// monitor location permission updates  in  settings
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        guard status != .notDetermined else { return }
        isPermissionDenied = status == .denied
        if status != .denied {
            /// fetching location immediately, faster than calling requestLocation( 2- 5 seconds to update)
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpateLocations locations: [CLLocation]) {
        guard let coordinates = locations.first?.coordinate else { return }

        /// Updating user coordinates and map camera position
        userCoordinate = coordinates
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 10000, longitudinalMeters: 10000)
        position = .region(region)

        manager.stopUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didFailWithError _: any Error) {
        /// error handling
    }

    /// add property in info.plist file
    func requestUserLocation() {
        manager.requestWhenInUseAuthorization()
    }
}
