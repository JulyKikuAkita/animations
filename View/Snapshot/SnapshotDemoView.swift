//
//  SnapshotDemoView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS-only — wrapped in `#if canImport(UIKit)` because the underlying
//  `drawHierarchy(in:afterScreenUpdates:)` is a UIKit API.
//
//  ⚠️  Preview may crash because the `.snapshot` modifier relies on
//      `UIViewRepresentable + drawHierarchy(...)`, which requires a
//      real `UIWindow` hierarchy that doesn't exist in the Xcode
//      preview canvas. Run on a simulator/device.
//
//  See: `Helpers/Extensions/Snapshot.swift` for the modifier itself.
//
//  TODO: Cleanup
//        `SnapshotDemoImageView` (lines ~67–94) is a SECOND demo
//        showing snapshot of a small content block, but the
//        `#Preview` only renders `SnapshotDemoView`. Either expose
//        `SnapshotDemoImageView` in a `TabView`/list so both are
//        visible, or delete it. Right now you have to manually
//        edit the `#Preview` to see the second demo.
//
//  Learning point
//  ──────────────
//  Programmatic screenshot of a SwiftUI view tree → `UIImage`. Two
//  variations:
//    • `SnapshotDemoView` — snapshots an entire `NavigationStack +
//      List`, then overlays the captured image fullscreen with a
//      tap-to-dismiss backdrop. Demonstrates the workflow when the
//      whole screen is the source.
//    • `SnapshotDemoImageView` — snapshots just a small custom
//      "Image + Text" card and renders the result directly below.
//      Demonstrates that the modifier works at any granularity.
//
//  Trigger model:
//    • `@State trigger: Bool` flips on button tap.
//    • `.snapshot(trigger:onSnapshot:)` watches the trigger via
//      `onChange` and runs the snapshot when it flips. The Bool is
//      a "fire signal" — the value itself doesn't matter, just
//      that it CHANGED.
//
//  Why this can't be a SwiftUI-native API
//  ──────────────────────────────────────
//  SwiftUI has `ImageRenderer` (iOS 16+) which can render a View to
//  an image, but it RE-LAYS-OUT the view in a fresh context — losing
//  any current scroll position, gesture state, navigation depth,
//  etc. `drawHierarchy` snapshots the LIVE on-screen pixels of the
//  hosting `UIView`, including all of that state. That's why this
//  demo bridges through UIKit instead of using `ImageRenderer`.
//
//  Key APIs
//  ────────
//  • `.snapshot(trigger:onSnapshot:)` — project helper at
//    `Helpers/Extensions/Snapshot.swift`. Internally wraps a
//    `UIViewRepresentable` that calls `drawHierarchy(in:afterScreenUpdates:)`
//    on the host view's `superview`.
//  • `Image(uiImage:)` — render the captured `UIImage` back inside
//    SwiftUI; pair with `.resizable() + .aspectRatio(.fit)` for
//    rendering at the overlay size.
//  • `#if canImport(UIKit)` — guard the whole file because the
//    underlying API is iOS-specific. macOS would need
//    `NSView.cacheDisplay(in:to:)` or similar.
//
//  How to apply
//  ────────────
//  Reach for this when you need pixel-accurate snapshots that
//  preserve LIVE state — share-sheet thumbnails, "save chart as
//  image", in-app debug captures. Otherwise prefer
//  `ImageRenderer` (iOS 16+) — it's pure SwiftUI and doesn't have
//  the UIWindow-required preview-crash caveat.
//
//  See also
//  ────────
//  • Helpers/Extensions/Snapshot.swift — the `.snapshot` modifier.
//  • View/Button/AnimatedConfirmationButtonDemoView.swift — uses
//    `ImageRenderer` for a different snapshot use case (zoom-from-
//    icon hero animation), worth comparing the trade-offs.
//
import SwiftUI

#if canImport(UIKit)
    struct SnapshotDemoView: View {
        @State private var trigger: Bool = false
        @State private var snapshot: UIImage?
        var body: some View {
            NavigationStack {
                List {
                    ForEach(1 ... 20, id: \.self) { index in
                        Text("List Cell \(index)")
                    }
                }
                .navigationTitle("List View")
                .toolbar {
                    ToolbarItem {
                        Button("Take Snapshot") {
                            trigger.toggle()
                        }
                    }
                }
            }
            .snapshot(trigger: trigger) {
                snapshot = $0
            }
            .overlay {
                if let snapshot {
                    Image(uiImage: snapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 15))
                        .padding(15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            Rectangle()
                                .fill(.black.opacity(0.3))
                                .ignoresSafeArea()
                                .onTapGesture {
                                    self.snapshot = nil
                                }
                        }
                }
            }
        }
    }

    struct SnapshotDemoImageView: View {
        @State private var trigger: Bool = false
        @State private var snapshot: UIImage?
        var body: some View {
            VStack(spacing: 25) {
                Button("Take Snapshot") {
                    trigger.toggle()
                }

                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                    Text("Dan Da Dan")
                }
                .foregroundStyle(.white)
                .padding()
                .background(.brown.gradient, in: .rect(cornerRadius: 15))
                .snapshot(trigger: trigger) {
                    snapshot = $0
                }

                if let snapshot {
                    Image(uiImage: snapshot)
                        .aspectRatio(contentMode: .fit)
                }
            }
        }
    }

    #Preview {
        SnapshotDemoView()
    }
#endif
