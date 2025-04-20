//
//  LocationPickerManager.swift
//  animation

import CoreLocation
import MapKit
import SwiftUI

struct LocationPickerView: View {
    @Binding var isPresented: Bool
    var coordinate: (CLLocationCoordinate2D?) -> Void
    /// View Properties
    @StateObject private var manager: LocationManager = .init()
    @State private var selectedCoordinates: CLLocationCoordinate2D?
    /// Environment Properties
    @Namespace private var mapSpace
    @FocusState private var isKeyboardActive: Bool
    @Environment(\.openURL) var openURL
    var body: some View {
        ZStack {
            if let isPermissionDenied = manager.isPermissionDenied {
                if isPermissionDenied {
                    noPermissionView()
                } else {
                    ZStack {
                        searchResultView()

                        mapView()
                            .safeAreaInset(edge: .bottom, spacing: 0) {
                                selectLocationButton()
                            }
                            .opacity(manager.showSearchResults ? 0 : 1)
                            .ignoresSafeArea(.keyboard, edges: .all)
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        mapSearchBar()
                    }
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
        .animation(.easeInOut(duration: 0.25), value: manager.showSearchResults)
    }

    func searchCardView(_ mark: MKPlacemark) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(mark.name ?? "")
                    Text(mark.title ?? mark.subtitle ?? "")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark")
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .opacity(manager.selectedPlaceMark == mark ? 1 : 0)
            }

            Divider()
        }
        .contentShape(.rect)
        .onTapGesture {
            isKeyboardActive = false
            manager.updateMapPosition(to: mark)
        }
    }

    func searchResultView() -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(manager.searchResultsPlaceMarks, id: \.self) { mark in
                    searchCardView(mark)
                }
            }
            .padding(15)
        }
        .frame(maxWidth: .infinity)
        .background(.background)
    }

    func selectLocationButton() -> some View {
        Button {
            isPresented = false
            coordinate(selectedCoordinates)
        } label: {
            Text("Select Location")
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
        }
        .padding(15)
        .background(.background)
    }

    func mapSearchBar() -> some View {
        VStack(spacing: 15) {
            Text("Select Location")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button {
                        if manager.showSearchResults {
                            manager.clearSearchResults()
                            manager.showSearchResults = false
                        } else {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .contentShape(.rect)
                    }
                }

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)

                TextField("Search", text: $manager.searchText)
                    .padding(.vertical, 10)
                    .focused($isKeyboardActive)
                    .submitLabel(.search)
                    .onSubmit {
                        /// close the view if search text is empty
                        if manager.searchText.isEmpty {
                            manager.clearSearchResults()
                        } else {
                            manager.searchForPlaces()
                        }
                    }
                    .onChange(of: isKeyboardActive) { _, newValue in
                        if newValue {
                            manager.showSearchResults = true
                        }
                    }
                    .contentShape(.rect)

                if manager.showSearchResults {
                    /// clear button at end of search textfield
                    Button {
                        manager.clearSearchResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                    .opacity(manager.isSearching ? 0 : 1)
                    .overlay {
                        ProgressView()
                            .opacity(manager.isSearching ? 1 : 0)
                    }
                }
            }
            .padding(.horizontal, 15)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
        }
        .padding(15)
        .background(.background)
    }

    func mapView() -> some View {
        Map(position: $manager.position) {
            /// testing, mark on coordinate
//            if let selectedCoordinates {
//                Marker("selected", coordinate: selectedCoordinates)
//            }
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton(scope: mapSpace)
            MapCompass(scope: mapSpace)
            MapPitchToggle(scope: mapSpace)
        }
        .overlay {
            // draw a pin on search result placemark
            Image(systemName: "mappin.and.ellipse")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
                .foregroundStyle(.red.gradient)
                .shadow(radius: 4)
                /// centering the pin
                .offset(y: -17)
                .allowsHitTesting(false)
        }
        .mapScope(mapSpace)
        .onMapCameraChange { cameraPosition in
            manager.currentRegion = cameraPosition.region
            selectedCoordinates = cameraPosition.region.center
        }
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

            /// Try again and go to settings buttons
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
    /// Search properties
    @Published var searchText: String = ""
    @Published var searchResultsPlaceMarks: [MKPlacemark] = []
    @Published var showSearchResults: Bool = false
    @Published var isSearching: Bool = false
    @Published var selectedPlaceMark: MKPlacemark?

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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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

    func searchForPlaces() {
        guard let currentRegion else { return }
        Task { @MainActor in
            isSearching = true

            let request = MKLocalSearch.Request()
            request.region = currentRegion
            request.naturalLanguageQuery = searchText
            guard let response = try? await MKLocalSearch(request: request).start() else {
                isSearching = false
                return
            }
            searchResultsPlaceMarks = response.mapItems.compactMap(\.placemark)
            isSearching = false
        }
    }

    func clearSearchResults() {
        searchText = ""
        searchResultsPlaceMarks = []
    }

    func updateMapPosition(to placemark: MKPlacemark) {
        let coordinates = placemark.coordinate
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 700, longitudinalMeters: 700)
        position = .region(region)
        selectedPlaceMark = placemark
        showSearchResults = false
    }
}

#Preview {
    LocationPickerDemoView()
}
