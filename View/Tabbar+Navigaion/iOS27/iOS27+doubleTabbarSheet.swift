//
//  iOS27+doubleTabBarSheet.swift
//  animation
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
