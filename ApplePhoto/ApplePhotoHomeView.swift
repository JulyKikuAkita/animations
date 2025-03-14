//
//  ApplePhotoHomeView.swift
//  demoApp
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
                .opacity(coordinator.animateView ? 1 - coordinator.dragProgress : 0)
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
               let dAnchor = value[selectedItem.id + "DEST"]
            {
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
        @Bindable var bindableCoordinator = coordinator
        ScrollViewReader { reader in /// scrollPosition modifier causes scrollview to stutter w/ lazeGrid; use scrollViewReader as alternative
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text("Recents")
                        .font(.largeTitle.bold())
                        .padding(.top, 20)
                        .padding(.horizontal, 15)

                    LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: 3), spacing: 3) {
                        ForEach($bindableCoordinator.items) { $item in
                            GridImageView(item)
                                .id(item.id)
                                .didFrameChange { frame, bounds in
                                    let minY = frame.minY // > height item is scrolled away in a downward direction
                                    let maxY = frame.maxY // <0 item is scrolled away in upward direction
                                    let height = bounds.height

                                    if maxY < 9 || minY > height {
                                        item.appeared = false
                                    } else {
                                        item.appeared = true
                                    }
                                }
                                .onDisappear { // address LazyVGrid
                                    item.appeared = false
                                }
                                .onTapGesture {
                                    coordinator.selectedItem = item
                                }
                        }
                    }
                    .padding(.vertical, 15)
                }
            }
            .onChange(of: coordinator.selectedItem) { _, newValue in
                if let item = coordinator.items.first(where: { $0.id == newValue?.id }),
                   !item.appeared
                {
                    /// Scroll to this item, as this is not visible on the screen
                    reader.scrollTo(item.id, anchor: .bottom)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Image view for grid
    @ViewBuilder
    func GridImageView(_ item: PhotoItem) -> some View {
        GeometryReader {
            let size = $0.size

            Rectangle()
                .fill(.clear)
                .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
                    [item.id + "SOURCE": anchor]
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
