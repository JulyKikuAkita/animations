//
//  PermissionSheetDemo.swift
//  animation
//
//  Created on 7/25/25.
import AVKit
import CoreLocation
import PhotosUI
import SwiftUI

// iOS 26
struct PermissionSheetDemo: View {
    var body: some View {
        NavigationStack {
            List {}
                .navigationTitle("Permission Sheet")
        }
        .permisisonSheet([.location, .camera, .microPhone, .photoLibrary])
    }
}

extension View {
    func permisisonSheet(_ permissions: [Permission]) -> some View {
        modifier(PermissionSheetViewModifier(permissions: permissions))
    }
}

private struct PermissionSheetViewModifier: ViewModifier {
    init(permissions: [Permission]) {
        let initialStates = permissions.sorted(by: {
            $0.orderedIndex < $1.orderedIndex
        }).compactMap {
            PermissionState(id: $0)
        }
        _states = .init(initialValue: initialStates)
    }

    @State private var showSheet: Bool = false
    @State private var states: [PermissionState]
    @State private var currentIndex: Int = 0
    var locationManager = LocationManager()
    @Environment(\.openURL) var openURL

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showSheet) {
                VStack(spacing: 20) {
                    Text("Required Permissions")
                        .font(.title)
                        .fontWeight(.bold)

                    Image(systemName: isAllGranted ? "person.badge.shield.checkmark" : "person.badge.shield.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 100, height: 100)
                        .background {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.blue.gradient)
                        }

                    /// Permission rows
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(states) { state in
                            permissionRow(state: state)
                                .contentShape(.rect)
                                .onTapGesture {
                                    requestPermission(state.id.orderedIndex)
                                }
                        }
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 0)

                    Button {
                        showSheet = false
                    } label: {
                        Text("Start using the App")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.blue.gradient, in: .capsule)
                    }
                    .disabled(!isAllGranted)
                    .opacity(isAllGranted ? 1 : 0.6)
                    .overlay(alignment: .top) {
                        if isThereAnyRejection {
                            Button("Go to Settings") {
                                if let appSettingsURL = URL(
                                    string: UIApplication.openSettingsURLString)
                                {
                                    openURL(appSettingsURL)
                                }
                            }
                            .offset(y: -30)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .presentationDetents([.height(480)])
                .interactiveDismissDisabled()
            }
            .onChange(of: locationManager.status) { _, _ in
                if let status = locationManager.status,
                   let index = states.firstIndex(where: { $0.id == .location })
                {
                    if status == .notDetermined {
                        showSheet = true
                        states[index].isGranted = nil
                        requestPermission(index)
                    } else if status == .denied || status == .restricted {
                        showSheet = true
                        states[index].isGranted = false
                    } else {
                        states[index].isGranted = (
                            status == .authorizedAlways || status == .authorizedWhenInUse
                        )
                    }
                }
            }
            .onChange(of: currentIndex) { _, newValue in
                guard states[newValue].isGranted == nil else { return }
                requestPermission(newValue)
            }
            .onAppear {
                showSheet = !isAllGranted
                if let firstRequestPermission = states.firstIndex(where: { $0.isGranted == nil }) {
                    currentIndex = firstRequestPermission
                    requestPermission(firstRequestPermission)
                }
            }
    }

    private func permissionRow(state: PermissionState) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(.gray, lineWidth: 1)

                Group {
                    if let isGranted = state.isGranted {
                        Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isGranted ? .green : .red)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
                .font(.title3)
                .transition(.symbolEffect)
            }
            .frame(width: 22, height: 22)

            Text(state.id.rawValue)
        }
        .lineLimit(1)
    }

    private var isAllGranted: Bool {
        states.filter {
            if let isGranted = $0.isGranted {
                return isGranted
            }
            return false
        }.count == states.count
    }

    private var isThereAnyRejection: Bool {
        states.contains(where: { $0.isGranted == false })
    }

    private struct PermissionState: Identifiable {
        var id: Permission
        /// dynamic update
        var isGranted: Bool?

        init(id: Permission) {
            self.id = id
            isGranted = id.isGranted
        }
    }

    private func requestPermission(_ index: Int) {
        Task { @MainActor in
            let permission = states[index].id

            switch permission {
            case .location:
                locationManager.requestWhenInUseAuthorization()
            case .camera:
                let status = await AVCaptureDevice.requestAccess(for: .video)
                states[index].isGranted = status
            case .microPhone:
                let status = await AVCaptureDevice.requestAccess(for: .audio)
                states[index].isGranted = status
            case .photoLibrary:
                let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                /// Limited is optional
                states[index].isGranted = status == .authorized || status == .limited
            }

            currentIndex = min(currentIndex + 1, states.count - 1)
        }
    }
}

#Preview {
    PermissionSheetDemo()
}

@Observable
@MainActor private class LocationManager: NSObject, CLLocationManagerDelegate {
    var status: CLAuthorizationStatus?
    var manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
}
