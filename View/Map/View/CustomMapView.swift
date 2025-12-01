//
//  CustomMapView.swift
//  animation
//
//  Created on 11/29/25.
// support ios18+

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
            /// buttomCarousel use safeAreaInset to let map legal link visible
            .safeAreaInset(edge: .bottom, spacing: 0) {
                GeometryReader {
                    let size = $0.size
                    buttomCarousel(size)

                    /// a temp card until plces is full loaded
                    if places.isEmpty {
                        ButtomCarouselCardView(
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
                            Image(systemName: "xmark,circle.fill")
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

    private func buttomCarousel(_ size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(places) { place in
                    ButtomCarouselCardView(
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
