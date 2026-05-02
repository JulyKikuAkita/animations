//
//  ContentView.swift
//  Alert

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var sceneDelegate: SceneDelegate?

    var body: some View {
        Group {
            if let sceneDelegate {
                CustomAlertDemoView()
                    .environment(sceneDelegate)
            } else {
                ProgressView()
            }
        }
        // Why not `SceneDelegate()`?
        //   That creates a fresh, unconnected instance with no windowScene,
        //   so its overlayWindow is never set up and `alert.present()`
        //   silently fails.
        //
        // Why `SceneDelegate.current`, not `scene.delegate`?
        //   Under SwiftUI's App lifecycle, `scene.delegate` is
        //   `SwiftUI.AppSceneDelegate`, not our custom class. UIKit still
        //   instantiates our class and fires `willConnectTo` on it (see
        //   AppDelegate.swift), which is where we stash it on `current`.
        .onAppear {
            sceneDelegate = SceneDelegate.current
        }
    }
}

#Preview {
    ContentView()
}
