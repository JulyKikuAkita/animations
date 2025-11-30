//
//  CustomMapView.swift
//  animation
//
//  Created on 11/29/25.

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
//            CustomMapView()
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
    /// Environment Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition)
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
                            ButtomCarouselCardView()
                                .padding(.horizontal, 15)
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
        .onAppear {
            guard places.isEmpty else { return }
            fetchPlaces()
        }
    }

    private func buttomCarousel(_: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(places) { place in
                    ButtomCarouselCardView(place: place)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled(true)
        .scrollTargetBehavior(.paging)
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
                }
            }
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

struct ButtomCarouselCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    var place: Place?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let place {
                Text(place.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(place.address)
                    .lineLimit(2)

                if let phoneNumber = place.phoneNumber,
                   let url = URL(string: "tel: \(phoneNumber)")
                {
                    Link("Phone Number: **\(phoneNumber)**", destination: url)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer(minLength: 0)

                Button {} label: {
                    Text("Learn More")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .buttonBorderShape(.capsule)

            } else {
                /// Dummy placeholder items
                Group {
                    Text("PLACEHOLDER NAME")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("This is a placeholder address. Replace with actual address.")
                        .lineLimit(2)

                    Text("xxx-xxx-xxxx")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Spacer(minLength: 0)

                    Button {} label: {
                        Text("Learn More")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .buttonBorderShape(.capsule)
                    .disabled(true)
                }
                .redacted(reason: .placeholder)
            }
        }
        .padding(15)
        .optionalGlassEffect(colorScheme)
    }
}
