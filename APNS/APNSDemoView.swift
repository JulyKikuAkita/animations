//
//  APNSDemoView.swift
//  animation
//
// route notification link
// 1. use navigation link
// 2. Use deep link to route notification is not limited to navigation path, we can route to any pages, sheets, alerts, dialogs, etc.
//
import SwiftUI

//@main
struct APNSDemoAPNSDemoView: App {
    @UIApplicationDelegateAdaptor(AppData.self) private var appData
    var body: some Scene {
        WindowGroup {
            APNSDemoView()
                .environment(appData)
                .onOpenURL { url in
                    if let pageName = url.host() {
                        /// adding the view to navigation stack
                        appData.mainPageNavigationPath.append(pageName)
                    }
                }
        }
    }
}

@Observable
class AppData: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var mainPageNavigationPath: [String] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        /// showing alert even when app is active
        return [.sound, .banner]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let pageLink = response.notification.request.content.userInfo["pageLink"] as? String {
            /// Use navigation link to route notification link
//            if mainPageNavigationPath.last != pageLink {
//                /// optional: mainPageNavigationPath = [] if want to remove all previous pages
//               /// push new page
//                mainPageNavigationPath.append(pageLink)
//            }

            /// Use deep link  to route notification link
            guard let url = URL(string: pageLink) else { return }
            UIApplication.shared.open(url, options: [:]) { _ in

            }
        }
    }
}

struct APNSDemoView: View {
    @Environment(AppData.self) private var appData
    var body: some View {
        @Bindable var appData = appData
        NavigationStack(path: $appData.mainPageNavigationPath) {
            List {
                NavigationLink("View 1", value: "View 1")
                NavigationLink("View 2", value: "View 2")
                NavigationLink("View 3", value: "View 3")
            }
            .navigationTitle("Notification Deep Link")
            .navigationDestination(for: String.self) { value in
                    Text("Hello from \(value)")
                        .navigationTitle(value)
            }
        }
        .task {
            /// Notification Permission
            let _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }
}

#Preview {
    @UIApplicationDelegateAdaptor(AppData.self) var appData
    APNSDemoView()
        .environment(appData)
}
