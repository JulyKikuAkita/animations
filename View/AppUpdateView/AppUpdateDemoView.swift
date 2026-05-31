//
//  AppUpdateDemoView.swift
//  animation
//
//  Created on 10/11/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cleanup candidates
//        1. The illustration overlay locks itself to the actual
//           asset dimensions (`399 × 727`, `logoSize: 100×100`,
//           `logoPlacement: 173×365`). If `Image(.appUpdate)` is
//           ever swapped for a different asset, the logo will land
//           in the wrong spot. Document the dependency or replace
//           with a SafeAreaInset-style overlay that doesn't depend
//           on absolute pixel coordinates.
//        2. The mock at the bottom (`mockcheckIfAppUpdateAvailable`)
//           is `#if DEBUG`-gated — fine. But the call site uses it
//           unconditionally, so a release build wouldn't have a
//           mock to fall back on. If this file ever ships, replace
//           with a real `checkIfAppUpdateAvailable` implementation
//           in `Helpers/Managers/VersionCheckManager.swift`.
//
//  Learning point
//  ──────────────
//  In-app update prompt: on view appear, ask `VersionCheckManager`
//  whether a newer build is available; if yes, present a sheet with
//  "Update" / "No Thanks" buttons (or just "Update" for forced
//  updates). The headline UX trick is the FORCED variant:
//  `interactiveDismissDisabled(forcedUpdate)` blocks pull-to-dismiss
//  AND hides the "No Thanks" button, so a critical-fix release can't
//  be skipped by the user.
//
//  Forced-update detection is content-based: the demo treats
//  `releaseNotes.contains("critical fix")` as a force-trigger.
//  Real apps would use a server-side flag instead — keep that in
//  mind if you copy this pattern.
//
//  Key APIs
//  ────────
//  • `.sheet(item: ...)` — drives presentation off the optional
//    `updateAppInfo` so the sheet only appears when the version
//    check actually returns a result.
//  • `.interactiveDismissDisabled(_:)` — gates pull-down dismiss;
//    paired with hiding the No-Thanks button to enforce the update.
//  • `.presentationDetents([.height(450)])` — fixed-height sheet
//    rather than full medium/large; matches the illustration's
//    intrinsic size.
//  • `.presentationBackground(.background)` — strips the default
//    sheet background so the illustration's edges read cleanly.
//  • `@Environment(\.openURL)` — opens the App Store URL without
//    a UIApplication import.
//  • `isiOS26OrLater` — project helper; iOS 26 changed sheet inset
//    behaviour, so the bottom padding / `ignoresSafeArea` branch.
//
//  How to apply
//  ────────────
//  Wire `VersionCheckManager` to your real backend (App Store
//  Connect API, custom service, etc.), then drop this view into
//  your root scene. Use `forcedUpdate: true` ONLY for critical
//  fixes — blocking dismissal is a heavy hand and degrades UX if
//  overused.
//
//  See also
//  ────────
//  • AppRatingDemoView.swift — sibling demo for the in-app rating
//    prompt; same folder, different intent.
//  • Helpers/Managers/VersionCheckManager.swift — the manager this
//    file consumes. Production version check logic should live
//    there, not here.
//
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
                    "There is an app update available from\nversion **\(appInfo.currentVersion)** to version **\(appInfo.availableVersion)**!"
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
