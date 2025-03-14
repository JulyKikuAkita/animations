//
//  ContentView.swift
//  Orientation
//

import SwiftUI

struct ContentView: View {
    @State private var orientation: Orientation = .portrait
    @State private var showFullScreenCover: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section("Orientation") {
                    Picker("", selection: $orientation) {
                        ForEach(Orientation.allCases, id: \.rawValue) { orientation in
                            Text(orientation.rawValue)
                                .tag(orientation)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: orientation, initial: true) { _, newValue in
                        modifyOrientation(newValue.mask)
                    }
                }

                Section("Actions") {
                    NavigationLink("Detail View") {
                        DetailView(userSelection: orientation)
                    }

                    Button("Show full screen cover") {
                        modifyOrientation(.landscapeRight)
                        DispatchQueue.main.async { /// animation delay
                            showFullScreenCover.toggle()
                        }
                    }
                }
            }
            .navigationTitle("Set Orientation")
            .fullScreenCover(isPresented: $showFullScreenCover) {
                Rectangle()
                    .fill(.red.gradient)
                    .overlay {
                        Text("Fullscreen cover")
                    }
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button("Close") {
                            modifyOrientation(orientation.mask)
                            showFullScreenCover.toggle()
                        }
                        .padding(15)
                    }
            }
        }
    }
}

struct DetailView: View {
    var userSelection: Orientation
    @Environment(\.dismiss) private var dismiss
    @State private var isRotated: Bool = false
    var body: some View {
        NavigationLink("Sub-Detail View") {
            Text("Sub-Detail View")
                .onAppear {
                    modifyOrientation(.portrait)
                }
                .onDisappear {
                    modifyOrientation(.landscapeLeft)
                }
        }
        .onAppear {
            guard !isRotated else { return }
            modifyOrientation(.landscapeLeft) /// the only available option
            isRotated = true
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    modifyOrientation(userSelection.mask)
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

enum Orientation: String, CaseIterable {
    case all = "All"
    case portrait = "Portrait"
    case landscapeLeft = "Left"
    case landscapeRight = "Right"

    var mask: UIInterfaceOrientationMask {
        switch self {
        case .all:
            .all
        case .portrait:
            .portrait
        case .landscapeLeft:
            .landscapeLeft
        case .landscapeRight:
            .landscapeRight
        }
    }
}

extension View {
    func modifyOrientation(_ mask: UIInterfaceOrientationMask) {
        if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) {
            /// manual set orientation mask on App delegate
            AppDelegate.orientation = mask
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
            // update root VC
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
