//
//  ApplePhotoHomeView.swift
//  demoApp
//  TODO: https://www.youtube.com/watch?v=ktaGsPwGZpA&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=105
// creating hero layer 5:08
import SwiftUI

struct ApplePhotoHomeView: View {
    var coordinator: UICoordinator = .init()
    var body: some View {
        NavigationStack {
            HomeView()
                .environment(coordinator)
            /// disable home view interaction until detail view is visible
                .allowsHitTesting(coordinator.selectedItem == nil)
        }
        .overlay {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
                .opacity(coordinator.animateView ? 1 : 0)
        }
        .overlay {
            if coordinator.selectedItem != nil {
                DetailView()
                    .environment(coordinator)
                /// disabled until the showDetailView is visible
                    .allowsHitTesting(coordinator.showDetailView)
            }
        }
        /// we need to source and destination frame to animate the detailed view transition
        .overlayPreferenceValue(AnchorKey.self) { value in
            if let selectedItem = coordinator.selectedItem,
               let sAnchor = value[selectedItem.id + "SOURCE"],
               let dAnchor = value[selectedItem.id + "DEST"] {
                HeroLayer(
                    item: selectedItem,
                    sAnchor: sAnchor,
                    dAnchor: dAnchor
                )
                .environment(coordinator)
            }
                
        }
    }
}

struct HomeView: View {
    @Environment(UICoordinator.self) private var coordinator
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: 3), spacing: 3) {
                ForEach(coordinator.items) { item in
                    GridImageView(item)
                        .onTapGesture {
                            coordinator.selectedItem = item
                        }
                }
            }
            .padding(.vertical, 15)
        }
        .navigationTitle("Recents")
    }
    
    /// Image view for grid
    @ViewBuilder
    func GridImageView(_ item: PhotoItem) -> some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.clear)
                .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
                    return [item.id + "SOURCE": anchor]
                })
            
            if let previewImage = item.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .opacity(coordinator.selectedItem?.id == item.id ? 0 : 1)
            }
        }
        .frame(height: 130)
        .contentShape(.rect)
    }
}


#Preview {
    ApplePhotoHomeView()
}
