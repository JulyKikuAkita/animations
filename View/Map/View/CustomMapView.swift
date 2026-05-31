//
//  CustomMapView.swift
//  animation
//
//  Created on 11/29/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+; iOS 26 branch uses `Button(role: .cancel)` and
//  `MKMapItem.location.coordinate`.
//
//  Learning point
//  ──────────────
//  Apple-Maps-style "search nearby + scroll through results" demo:
//  shows a `Map` with annotated pins for nearby places matching a
//  search term (`"GameStop"`, `"Starbucks"`, etc.), with a paged
//  bottom carousel where each card represents one place. Selecting
//  a card animates the map's camera to centre on that place's pin
//  and pulses a ring around it; tapping "Learn More" presents a
//  zoom-transition sheet for that place.
//
//  Three pieces working together:
//    1. `MKLocalSearch` queries Apple's POI database scoped to a
//       region (here: `MKCoordinateRegion.applePark250K`). Returns
//       `MKMapItem`s converted to a local `Place` model.
//    2. The bottom carousel is a horizontal `LazyHStack` with
//       `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)`.
//       The `.onChange(of: selectedPlaceID)` updates
//       `cameraPosition` with a `withAnimation(animation)` so the
//       map flies to the new place as the user pages.
//    3. `matchedTransitionSource(id: place.id, in: animationID)` on
//       the carousel card + `.navigationTransition(.zoom(...))` on
//       the sheet creates the iOS 26 zoom transition.
//
//  Loading-state choreography
//  ──────────────────────────
//  While `places.isEmpty`, a redacted placeholder
//  `BottomCarouselCardView(place: nil, ...)` renders in the carousel
//  slot and a 35%-black overlay dims the map. As soon as
//  `MKLocalSearch` returns, both fade to their loaded state in a
//  single `withAnimation(animation)` block. This is the cleanest
//  pattern for "show something useful before the network resolves."
//
//  Key APIs
//  ────────
//  • `MKLocalSearch.Request` + `search.start()` — async POI lookup
//    scoped to a region.
//  • `Map(position: $cameraPosition)` + `MapCameraPosition.camera(...)`
//    — programmatic camera control. iOS 17+ MapKit-for-SwiftUI.
//  • `Annotation(_:coordinate:)` — declarative pin placement; the
//    closure body is the pin view.
//  • `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)` —
//    the paged carousel binding that drives the camera.
//  • `.matchedTransitionSource(id:in:)` + `.navigationTransition(.zoom(...))`
//    — iOS 26 zoom transition.
//  • `.safeAreaInset(edge: .bottom)` — keeps Apple's legal map
//    attribution visible above the carousel.
//
//  How to apply
//  ────────────
//  Use as a starting template for any "find me X near here" UX.
//  Drop the search query into a `@Binding` to make it interactive;
//  pair with [[LocationPermissionFullSheetView]] to gate access on
//  the user's "When in Use" permission.
//
//  See also
//  ────────
//  • View/Map/View/BottomCarouselCardView.swift — the carousel
//    card view.
//  • View/Map/View/PulseRingView.swift — the selected-pin pulse.
//  • View/Map/View/LocationPermissionFullSheetView.swift —
//    permission flow you'd use BEFORE this demo.
//  • View/CustomMenu/PopMenuiOS26+DatePickerDemo.swift — same
//    matched-transition + zoom-presentation pattern on a date
//    picker.
//
import MapKit
import SwiftUI

struct CustomMapDemoView: View {
    /// View Properties
    @State private var showView: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Button("show View") {
                    showView.toggle()
                }
            }
            .navigationTitle("Map Carousel")
        }
        .fullScreenCover(isPresented: $showView) {
            CustomMapView(
                userRegion: .applePark250K,
                userCoordinates: MKCoordinateRegion.applePark250K.center,
                lookupText: "GameStop",
                limit: 5
            )
        }
    }
}

struct CustomMapView: View {
    var userRegion: MKCoordinateRegion
    var userCoordinates: CLLocationCoordinate2D
    var lookupText: String
    var limit: Int
    init(
        userRegion: MKCoordinateRegion,
        userCoordinates: CLLocationCoordinate2D,
        lookupText: String,
        limit: Int = 10
    ) {
        self.userRegion = userRegion
        self.userCoordinates = userCoordinates
        self.lookupText = lookupText
        self.limit = limit
        _cameraPosition = .init(initialValue: .region(userRegion))
    }

    /// View Properties
    ///  For animated camera updates
    @State private var cameraPosition: MapCameraPosition
    @State private var places: [Place] = []
    @State private var selectedPlaceID: UUID? = nil
    @State private var expandedItem: Place?
    @Namespace private var animationID
    /// Environment Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(places) { place in
                    Annotation(place.name, coordinate: place.coordinates) {
                        annotationView(place)
                    }
                }
            }
            /// tmp background until place is fetched
            .overlay {
                loadingOverlay()
            }
            /// bottomCarousel use safeAreaInset to let map legal link visible
            .safeAreaInset(edge: .bottom, spacing: 0) {
                GeometryReader {
                    let size = $0.size
                    bottomCarousel(size)

                    /// a temp card until places is full loaded
                    if places.isEmpty {
                        BottomCarouselCardView(
                            place: nil,
                            expandedItem: $expandedItem
                        )
                        .padding(15)
                        .frame(width: size.width, height: size.height)
                    }
                }
                .frame(height: 200)
            }
            .navigationTitle("Nearby Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .sheet(item: $expandedItem) { place in
            DummySection(title: place.name)
                .presentationDetents([.medium])
                .navigationTransition(.zoom(sourceID: place.id, in: animationID))
        }
        .onAppear {
            guard places.isEmpty else { return }
            fetchPlaces()
        }
    }

    private func bottomCarousel(_ size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(places) { place in
                    BottomCarouselCardView(
                        place: place,
                        expandedItem: $expandedItem
                    )
                    .padding(15)
                    .frame(width: size.width, height: size.height)
                    .matchedTransitionSource(id: place.id, in: animationID)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled(true)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selectedPlaceID, anchor: .center)
        .onChange(of: selectedPlaceID) { _, newValue in
            guard let cooordinates = places.first(where: { $0.id == newValue })?.coordinates else { return }
            withAnimation(animation) {
                cameraPosition = .camera(.init(centerCoordinate: cooordinates, distance: 25000))
            }
        }
    }

    private func loadingOverlay() -> some View {
        Rectangle()
            .fill(.black.opacity(places.isEmpty ? 0.35 : 0))
            .ignoresSafeArea()
    }

    private func fetchPlaces() {
        Task {
            let request = MKLocalSearch.Request()
            request.region = userRegion
            request.naturalLanguageQuery = lookupText

            let search = MKLocalSearch(request: request)
            if let items = try? await search.start().mapItems {
                /// Converting mapItems into Place
                let places = items.compactMap { item in
                    let name = item.name ?? "Unknown"
                    var coordinates: CLLocationCoordinate2D = if #available(iOS 26.0, *) {
                        item.location.coordinate
                    } else {
                        item.placemark.coordinate
                    }
                    return Place(name: name, coordinates: coordinates, mapItem: item)
                }
                .prefix(limit).compactMap(\.self)

                withAnimation(animation) {
                    self.places = places
                    selectedPlaceID = places.first?.id
                }
            }
        }
    }

    private func annotationView(_ place: Place) -> some View {
        let isSelected: Bool = place.id == selectedPlaceID
        return Image(.sloth)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: isSelected ? 50 : 20, height: isSelected ? 50 : 20)
            .background {
                Circle()
                    .fill(.green)
                    .padding(-1)
            }
            // do Not animate the pulse ring view
            .animation(animation, value: isSelected)
            .background {
                if isSelected {
                    PulseRingView(tint: colorScheme == .dark ? .white : .gray,
                                  size: 80)
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                selectedPlaceID = place.id
            }
    }

    var animation: Animation {
        .smooth(duration: 0.45, extraBounce: 0)
    }
}

#Preview {
    CustomMapView(
        userRegion: .applePark250K,
        userCoordinates: MKCoordinateRegion.applePark250K.center,
        lookupText: "Starbucks",
        limit: 3
    )
}

#Preview("Navigation") {
    CustomMapDemoView()
}
