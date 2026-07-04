//
//  iOS27+doubleTabBarSheet.swift
//  animation
//
//  SwiftUI learning notes — key takeaways in this file:
//
//  Recreates Apple's Find My UI: a persistent bottom sheet over a full-screen
//  Map, where the sheet itself hosts a TabView, and tapping a device raises a
//  SECOND sheet that stacks above the first — the "double sheet" effect.
//
//  1. A TABVIEW INSIDE A SHEET. `SheetTabView` wraps `TabView` and is presented
//     via `.sheet`. The sheet never fully dismisses — its smallest detent
//     (`.height(95)`) keeps the tab bar peeking at the bottom, Find-My style.
//
//  2. PASSING TABS AS CONTENT — `@TabContentBuilder`. `SheetTabView` is generic
//     over `Selection` and `TabC: TabContent<Selection>`, so callers declare
//     `Tab { … }` items inline (like the trailing closure of a real `TabView`).
//     `@TabContentBuilder<Selection>` is the result builder that assembles them.
//     See the deep-dive at the `SheetTabView` declaration.
//
//  3. THE DOUBLE-SHEET TRICK — a REMAPPED detent binding. When the second sheet
//     is up (`isOtherSheetPresent`), the base sheet must shrink slightly so both
//     are visible. Instead of moving detents, we intercept the selection binding
//     and translate `.large` → `.fraction(0.98)` on the fly. See the deep-dive
//     at `.presentationDetents(detents, selection:)`.
//
//  4. PROGRESS DOWN THE TREE — a custom `@Entry` EnvironmentValue. The sheet
//     measures its own height with `.onGeometryChange`, converts it to a 0…1
//     `tabVisibilityProgress`, and publishes it via the environment so children
//     (e.g. `DeviceView`) can fade themselves out as the sheet collapses —
//     no binding plumbing required.
//
//  5. INTERACTING THROUGH THE SHEET. `.presentationBackgroundInteraction(
//     .enabled(upThrough: .large))` keeps the Map pannable behind the sheet, and
//     `.interactiveDismissDisabled()` stops a downward swipe from dismissing it.
//
//  Key APIs
//  ────────
//  • `TabContent` / `@TabContentBuilder<Selection>` (iOS 18+) — declarative tabs.
//  • `.presentationDetents(_:selection:)` with a computed `Binding` — dynamic
//    detent remapping.
//  • `.presentationBackgroundInteraction(.enabled(upThrough:))` — pass-through.
//  • `@Entry var … : CGFloat` in `EnvironmentValues` — one-line custom env value.
//  • `.onGeometryChange(for:_:action:)` — derive progress from live size.
//  • `.navigationTransition(.crossFade)` (iOS 26+) — tab-switch crossfade.
//
//  How to apply
//  ────────────
//  Use this whenever you want a resident bottom sheet that doubles as primary
//  navigation (maps, media players, Find My). The reusable nuggets: host a
//  TabView in a sheet with a small "peek" detent, and remap detents through a
//  computed binding to make a second sheet stack cleanly above the first.
//
import MapKit
import SwiftUI

@available(iOS 27.0, *)
struct DoubleSheetTabBarDemo: View {
    @State private var showTabView: Bool = true
    @State private var activeTab: AppleFindMyTab = .devices
    @State private var selectedDevice: Device?
    var body: some View {
        Map(initialPosition: .region(.applePark))
            .sheet(isPresented: $showTabView) {
                SheetTabView(selection: $activeTab, isOtherSheetPresent: selectedDevice != nil) {
                    Tab(value: .people) {} label: {
                        AppleFindMyTab.people.tabLabel
                    }

                    Tab(value: .devices) {
                        DeviceView(selectedDevice: $selectedDevice)
                    } label: {
                        AppleFindMyTab.devices.tabLabel
                    }

                    Tab(value: .items) {} label: {
                        AppleFindMyTab.items.tabLabel
                    }

                    Tab(value: .me) {} label: {
                        AppleFindMyTab.me.tabLabel
                    }
                }
            }
    }
}

@available(iOS 26.0, *)
struct DeviceView: View {
    @Binding var selectedDevice: Device?
    /// Read the 0…1 progress that `SheetTabView` publishes into the environment.
    /// It reflects how "open" the sheet is; we use it below to fade this content
    /// out as the sheet collapses toward its peek detent.
    @Environment(\.sheetTabVisibilityProgress) private var tabVisibilityProgress
    var body: some View {
        NavigationStack {
            List {
                ForEach(Device.data) { device in
                    HStack(spacing: 12) {
                        Image(systemName: device.symbol)
                            .font(.title)
                            .frame(width: 50, height: 50)
                            .background {
                                Circle()
                                    .fill(.background)
                            }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name)
                            Text(device.description)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }

                        Spacer(minLength: 0)

                        Text(device.location)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                    .listRowSeparator(Device.data.first?.id == device.id ? .hidden : .visible, edges: .top)
                    .listRowSeparatorTint(.gray.opacity(0.12))
                    .contentShape(.rect)
                    .onTapGesture {
                        selectedDevice = device
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {}
                }
            }
            .toolbarTitleDisplayMode(.inlineLarge)
        }
        .opacity(tabVisibilityProgress)
        .sheet(item: $selectedDevice) { device in
            IndividualDeviceView(device: device)
        }
    }
}

@available(iOS 26.0, *)
struct IndividualDeviceView: View {
    var device: Device
    @Environment(\.dismiss) private var dismiss
    /// View Properties
    @State private var activeDent: PresentationDetent = .large
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {}
                .navigationTitle(device.name)
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
        .padding(.top, 10)
        .presentationDetents([.height(95), .fraction(0.45), .large], selection: $activeDent)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled()
    }
}

@available(iOS 27.0, *)
struct SheetTabView<Selection: Hashable, TabC: TabContent<Selection>>: View {
    @Binding var selection: Selection
    var isOtherSheetPresent: Bool = false
    /// `@TabContentBuilder<Selection>` (iOS 18+) is a result builder — the tab
    /// equivalent of `@ViewBuilder`. It lets the caller pass a list of `Tab`
    /// values as a trailing closure, which the builder collects into a single
    /// `TabC` (the concrete `TabContent` type). This is what makes `SheetTabView`
    /// usable exactly like a native `TabView` while still being our own wrapper.
    @TabContentBuilder<Selection> var tabs: TabC
    /// View Properties
    @State private var tabVisibilityProgress: CGFloat = 0
    @State private var activeDetent: PresentationDetent = .height(95)
    var body: some View {
        TabView(selection: $selection) {
            tabs
        }
        .environment(\.sheetTabVisibilityProgress, tabVisibilityProgress)
        .navigationTransition(.crossFade)
        /// THE DOUBLE-SHEET DETENT REMAP
        /// ─────────────────────────────
        /// `selection:` takes a `Binding<PresentationDetent>` — we hand it a
        /// *computed* binding instead of `$activeDetent` directly so we can
        /// translate on read:
        ///   • get: if the user parked this sheet at `.large` AND a second sheet
        ///     is now presented, report `.fraction(0.98)` instead. That nudges
        ///     the base sheet down just enough that the stacked sheet above it
        ///     stays visible — the "two sheets at once" look.
        ///   • set: always store the user's real choice in `activeDetent`, so
        ///     once the second sheet closes we snap back to true `.large`.
        /// The extra `.fraction(0.98)` only exists in `detents` while the other
        /// sheet is present (see `detents` below), keeping it out of the normal
        /// snap points.
        .presentationDetents(detents, selection: .init(get: {
            if activeDetent == .large, isOtherSheetPresent {
                return .fraction(0.98)
            }
            return activeDetent
        }, set: { detent in
            activeDetent = detent
        }))
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled()
        .background {
            Rectangle()
                .foregroundStyle(.clear)
                /// Derive the 0…1 visibility progress from the sheet's own
                /// height. We subtract the peek height (~125pt) and clamp to a
                /// 100pt band, so progress is 0 while collapsed and ramps to 1
                /// as the sheet expands. Publishing it via the environment (see
                /// `.environment(\.sheetTabVisibilityProgress, …)` above) lets
                /// children fade with the sheet without any bindings.
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    let height = min(100, max(newValue.height - 125, 0))
                    let progress = height / 100
                    tabVisibilityProgress = progress
                }
                .ignoresSafeArea()
        }
    }

    var detents: Set<PresentationDetent> {
        if isOtherSheetPresent {
            return [.height(95), .fraction(0.45), .fraction(0.98), .large]
        }
        return [.height(95), .fraction(0.45), .large]
    }
}

extension EnvironmentValues {
    /// `@Entry` (iOS 18+) is the one-line way to declare a custom environment
    /// value — it generates the `EnvironmentKey` + `defaultValue` boilerplate
    /// for you. Default `1` means "fully visible" for any view read outside a
    /// `SheetTabView`.
    @Entry var sheetTabVisibilityProgress: CGFloat = 1
}

@available(iOS 27.0, *)
#Preview {
    DoubleSheetTabBarDemo()
}

extension AppleFindMyTab {
    @ContentBuilder
    var tabLabel: some View {
        Image(systemName: symbolImage)
        Text(rawValue)
    }
}
