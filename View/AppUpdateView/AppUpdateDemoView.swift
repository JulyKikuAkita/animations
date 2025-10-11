//
//  AppUpdateDemoView.swift
//  animation
//
//  Created on 10/11/25.

import SwiftUI

struct AppUpdateDemoView: View {
    @State private var updateAppInfo: VersionCheckManager.ReturnResult?
    var body: some View {
        NavigationStack {
            List {}
                .navigationTitle("App Update")
        }
        .sheet(item: $updateAppInfo, content: { info in
            let forcedAppUpdate: Bool = {
                if let notes = info.releaseNotes, !notes.isEmpty {
                    if notes.contains("critical fix") {
                        return true
                    }
                }
                return false
            }()
            AppUpdateView(appInfo: info, forcedUpdate: forcedAppUpdate)
        })
        .task {
            if let result = await VersionCheckManager.shared.mockcheckIfAppUpdateAvailable(
                forceUpdate: false
            ) {
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
                .overlay {
                    GeometryReader {
                        let size = $0.size
                        let actualImageSize = CGSize(width: 399, height: 727)
                        let ratio = min(
                            size.width / actualImageSize.width,
                            size.height / actualImageSize.height
                        )
                        let logoSize = CGSize(width: 100 * ratio, height: 100 * ratio)
                        let logoPlacement = CGSize(width: 173 * ratio, height: 365 * ratio)

                        if let appLogo = URL(string: appInfo.appLogo) {
                            AsyncImage(url: appLogo) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: logoSize.width, height: logoSize.height)
                                    .clipShape(.rect(cornerRadius: 30 * ratio))
                                    .offset(logoPlacement)
                            } placeholder: {}
                        }
                    }
                }

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

#if DEBUG
    extension VersionCheckManager {
        func mockcheckIfAppUpdateAvailable(forceUpdate: Bool = false) async -> ReturnResult? {
            .init(
                currentVersion: "1.1.1",
                availableVersion: "10.1.1",
                releaseNotes: forceUpdate ? "This is a critical fix." : "Enjoy the new version with improved features!",
                appLogo: "https://github.com/accounts/favicon.ico",
                appURL: "https://www.google.com"
            )
        }
    }
#endif
