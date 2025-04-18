//
//  NetworkMonitor.swift
//  animation

import Network
import SwiftUI

// need to pass the environment to the entry point
@main
struct NetworkMonitorDemoApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    var body: some Scene {
        WindowGroup {
            NetworkMonitorView()
                .environment(\.isNetworkConnected, networkMonitor.isConnected)
                .environment(\.connectionType, networkMonitor.connectionType)
        }
    }
}

struct NetworkMonitorView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.connectionType) private var connectionType
    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    Text((isConnected ?? false) ? "Connected" : "No Internet")
                }

                if let connectionType {
                    Section("Connection Type") {
                        Text(String(describing: connectionType).capitalized)
                    }
                }
            }
            .navigationTitle("Network Monitor")
        }
        .sheet(isPresented: .constant(!(isConnected ?? true))) {
            NoInternetView()
                .presentationDetents([.height(310)])
                .presentationCornerRadius(0)
                .presentationBackgroundInteraction(.disabled)
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
        }
    }
}

struct NoInternetView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.connectionType) private var connectionType
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 80, weight: .semibold))
                .frame(height: 100)

            Text("No Internet Connectivity")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Please check your internet connection and try again.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .lineLimit(2)

            Text("Waiting for Internet connection...")
                .font(.caption)
                .foregroundStyle(.background)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.primary)
                .padding(.top, 10)
                .padding(.horizontal, -20)
        }
        .fontDesign(.rounded)
        .padding([.horizontal, .top], 20)
        .background(.background)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(height: 310)
    }
}

extension EnvironmentValues {
    @Entry var isNetworkConnected: Bool?
    @Entry var connectionType: NWInterface.InterfaceType?
}

/**
  the retention  cycle:
  1.    NetworkMonitor owns monitor (strong reference).
  2.    monitor (an NWPathMonitor) retains its pathUpdateHandler closure.
  3.    The closure captures self strongly (if not marked [weak self]).
  NetworkMonitor ──► monitor (NWPathMonitor)
        ▲                          │
        │                          ▼
       self ◄─────── pathUpdateHandler (closure)

 The weak reference does not increase the retain count of self, so ARC can clean everything up safely when NetworkMonitor is deallocated.

  */
class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool?
    @Published var connectionType: NWInterface.InterfaceType?

    /// Monitor Properties
    private var queue = DispatchQueue(label: "Monitor")
    private var monitor = NWPathMonitor()

    init() {
        startMonitoring()
    }

    // Note:
    // NWPathMonitor’s pathUpdateHandler runs on a background queue (whatever you passed into monitor.start(queue:)),
    // but @Published properties must be mutated on the main thread with SwiftUI
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                self.isConnected = path.status == .satisfied

                let types: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .loopback]
                if let type = types.first(where: { path.usesInterfaceType($0) }) {
                    self.connectionType = type
                } else {
                    self.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        stopMonitoring()
    }

    private func stopMonitoring() {
        monitor.cancel()
    }
}

#Preview("Connected Preview") {
    NetworkMonitorView()
        .environment(\.isNetworkConnected, true)
        .environment(\.connectionType, .wifi)
}

#Preview("Disconnected Preview (Triggers Sheet)") {
    NetworkMonitorView()
        .environment(\.isNetworkConnected, false)
        .environment(\.connectionType, nil)
}
