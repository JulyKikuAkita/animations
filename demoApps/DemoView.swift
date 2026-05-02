//
//  DemoView.swift
//  demoApp

import SwiftUI

// Launcher for the demos this target ships.
//
// Each demo opens as a full-screen cover instead of a NavigationLink push.
// Why: most of these demos own their own `NavigationStack` / `TabView` at
// the root, and nesting those inside a push-style link hides the launcher's
// own back button. A fullScreenCover sidesteps that entirely and we add a
// "Close" affordance explicitly in one place.
//
// How to add a new demo:
//   1. Make sure the demo's source file is in the `demoApps` target.
//   2. Add a case to the `Demo` enum with a user-facing title as rawValue.
//   3. Add it to the matching Section in the List.
//   4. Add a branch in the switch inside `.fullScreenCover` that returns
//      the demo view.

struct ContentView: View {
    @State private var active: Demo?

    enum Demo: String, Identifiable, CaseIterable {
        case appleMusic = "Apple Music"
        case applePhotosIOS17 = "Apple Photos (iOS 17)"
        case photosIOS18 = "Photos (iOS 18)"
        case pinchZoom = "Pinch Zoom (Instagram-style feed)"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Apple app clones") {
                    row(.appleMusic)
                    row(.applePhotosIOS17)
                    row(.photosIOS18)
                }
                Section("Gestures") {
                    row(.pinchZoom)
                }
            }
            .navigationTitle("Demos")
        }
        .fullScreenCover(item: $active) { demo in
            ZStack(alignment: .topTrailing) {
                demoView(for: demo)

                Button {
                    active = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .shadow(radius: 4)
                }
                .padding()
                .accessibilityLabel("Close demo")
            }
        }
    }

    private func row(_ demo: Demo) -> some View {
        Button(demo.rawValue) { active = demo }
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private func demoView(for demo: Demo) -> some View {
        switch demo {
        case .appleMusic: AppleMusicHomeView()
        case .applePhotosIOS17: ApplePhotoHomeView()
        case .photosIOS18: PhotoAppIOS18DemoView()
        case .pinchZoom: PinchZoomDemoView()
        }
    }
}
