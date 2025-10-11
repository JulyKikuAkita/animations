//
//  AppUpdateDemoView.swift
//  animation
//
//  Created on 10/11/25.

import SwiftUI

struct AppUpdateDemoView: View {
    @State private var updateAppInfo: VersionCheckManager.ReturnResult?
    @State private var forcedAppUpdate: Bool = false
    var body: some View {
        NavigationStack {
            List {}
                .navigationTitle("App Update")
        }
        .sheet(item: $updateAppInfo, content: { info in
            AppUpdateView(appInfo: info, forcedUpdate: forcedAppUpdate)
        })
        .task {
            if let result = await VersionCheckManager.shared.checkIfAppUpdateAvailable() {
                updateAppInfo = result
            } else {
                print("No Updates Available!")
            }
        }
    }
}

struct AppUpdateView: View {
    var appInfo: VersionCheckManager.ReturnResult
    var forcedUpdate: Bool
    /// View Properties
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    var body: some View {
        VStack(spacing: 15) {
            Image(.appUpdate)
                .resizable()
                .aspectRatio(contentMode: .fit)

            VStack(spacing: 8) {
                Text("App Update Available")
                    .font(.title.bold())

                Text(
                    "There is an app update availblable from\nversion **\(appInfo.currentVersion)** to version **\(appInfo.availableVersion)**!"
                )
                .font(.callout)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 5)

            VStack(spacing: 8) {
                if let appURL = URL(string: appInfo.appURL) {
                    Button {
                        openURL(appURL)
                        if !forcedUpdate {
                            dismiss()
                        }
                    } label: {
                        Text("Update App")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }

                if !forcedUpdate {
                    Button {
                        dismiss()
                    } label: {
                        Text("No Thanks!")
                            .fontWeight(.medium)
                            .padding(.vertical, 5)
                            .contentShape(.rect)
                    }
                }
            }
        }
        .fontDesign(.rounded)
        .padding(20)
        .padding(.bottom, isiOS26OrLater ? 10 : 0)
        .presentationDetents([.height(450)])
        .interactiveDismissDisabled(forcedUpdate)
        .presentationBackground(.background)
        .ignoresSafeArea(.all, edges: isiOS26OrLater ? .all : [])
    }
}

#Preview {
    AppUpdateDemoView()
}
