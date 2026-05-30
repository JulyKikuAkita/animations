//
//  ProgressAlertDemoView.swift
//  animation
//
//  Created on 10/27/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  Works on iOS 17+; padding/offset constants branch on `isiOS26OrLater`
//  because UIAlertController's internal layout changed in iOS 26.
//
//  TODO: Cleanup candidates
//        1. `String(describing: type(of: $0)).contains("GroupHeaderScrollView")`
//           (line ~117) matches a PRIVATE UIKit class name. Apple
//           can rename or restructure that class between iOS versions
//           — the search will silently fail and the progress bar will
//           land at the fallback offset. The default `forceFallback: true`
//           sidesteps this in practice; consider deleting the
//           descendant-search branch entirely if no caller flips
//           `forceFallback` to false.
//        2. `static func dismantleUIView(...) { debugPrint("tear down called") }`
//           (line ~127) is a leftover diagnostic. Remove the print
//           or remove the function — it's not needed for correctness.
//        3. `DispatchQueue.main.asyncAfter(deadline: .now()) { ... }`
//           (line ~81) is a "next runloop" hop dressed as a delayed
//           call. `DispatchQueue.main.async { ... }` reads cleaner.
//
//  Learning point
//  ──────────────
//  SwiftUI's `.alert(...)` modifier intentionally only allows
//  title / message / actions — there's no API for "put a progress
//  bar inside the alert." This file works around that by reaching
//  through SwiftUI to grab the live `UIAlertController` and
//  injecting a `UIProgressView` as a child of its view hierarchy.
//  Nothing in `UIAlertController`'s public API supports this; the
//  whole technique is structured introspection.
//
//  Mechanics:
//    1. The `.progressAlert(...)` extension calls the standard
//       SwiftUI `.alert(...)` for chrome (title / message / cancel),
//       then attaches a `UIViewRepresentable` via `.background { }`
//       that runs ALONGSIDE the alert presentation.
//    2. Inside the representable's `makeUIView`, the code walks
//       `UIApplication.shared.connectedScenes.first → keyWindow →
//       rootViewController → presentedViewController` and casts
//       the result to `UIAlertController`.
//    3. A fresh `UIProgressView` is added as a subview of the
//       alert controller's `.view`, with Auto Layout constraints
//       pinning it to the controller's leading/trailing edges +
//       a hand-tuned vertical offset.
//    4. `updateUIView` re-applies the latest `progress` value on
//       every SwiftUI update tick, since SwiftUI's diff doesn't
//       know about the UIKit child view.
//
//  Why two positioning modes (`forceFallback`)?
//  ────────────────────────────────────────────
//  • `forceFallback: true` (default) — uses a hardcoded
//    `fallbackOffset: 50` from the alert's top edge. Stable across
//    iOS versions; doesn't care about UIKit internals.
//  • `forceFallback: false` — searches the alert's view tree for
//    a private `GroupHeaderScrollView` and positions the progress
//    view immediately under it. Looks tighter, but fragile (see
//    TODO: #1).
//
//  Key APIs
//  ────────
//  • `UIViewRepresentable.makeUIView` / `updateUIView` — the standard
//    SwiftUI ↔ UIKit bridge. Used here for SIDE EFFECTS, not for
//    rendering anything visible (the host UIView stays clear).
//  • `UIApplication.shared.connectedScenes` chain to find the live
//    presented `UIAlertController`. Marked `private`; this is the
//    fragile part.
//  • `View.allDescendants()` — project helper (recursive subview
//    walker) used to locate the private `GroupHeaderScrollView`.
//  • `isiOS26OrLater` — project helper for version-branched padding.
//    The system alert layout shifted slightly in iOS 26, so 30pt
//    versus 15pt insets keep the progress bar from clipping.
//
//  How to apply
//  ────────────
//  Use ONLY when the system alert is non-negotiable (e.g., HIG
//  consistency, or you really need the system's blur/dim chrome).
//  Otherwise build a custom sheet — you'll spend less time fighting
//  UIKit internals. If you do use this, keep `forceFallback: true`
//  and accept the looser layout.
//
//  See also
//  ────────
//  • View/Alert/* — sibling alert demos, mostly pure-SwiftUI
//    custom alerts that avoid this introspection altogether.
//
import SwiftUI

struct ProgressAlertDemoView: View {
    @State private var showAlert: Bool = false
    @State private var progress: CGFloat = 0.2
    @State private var config: ProgressAlertConfig = .init(title: "Downloading\n",
                                                           message: "Almost there...\nGiving it an extra push!")

    var body: some View {
        NavigationStack {
            List {
                Button("Show Alert") {
                    showAlert.toggle()
                    /// mock progress
                    Task {
                        for _ in 1 ... 10 {
                            try? await Task.sleep(for: .seconds(0.8))
                            progress += 0.1
                        }
                    }
                }
            }
            .navigationTitle(Text("Progress Alert Demo"))
            .progressAlert(config: config, isPresented: $showAlert, progress: $progress) {
                Button("Cancel", role: .cancel) {
                    progress = 0
                }
            }
        }
    }
}

struct ProgressAlertConfig {
    var tint: Color = .blue
    var title: String
    var message: String
    var fallbackOffset: CGFloat = 50
    var forceFallback: Bool = true
}

#Preview {
    ProgressAlertDemoView()
}

extension View {
    func progressAlert(
        config: ProgressAlertConfig,
        isPresented: Binding<Bool>,
        progress: Binding<CGFloat>,
        @ViewBuilder actions: @escaping () -> some View
    ) -> some View {
        alert(config.title, isPresented: isPresented) {
            actions()
        } message: {
            Text("\(config.message)\(config.forceFallback ? "" : "\n")")
        }.background {
            if isPresented.wrappedValue {
                AttachProgressWithAlert(config: config, progress: progress)
            }
        }
    }
}

private struct AttachProgressWithAlert: UIViewRepresentable {
    var config: ProgressAlertConfig
    @Binding var progress: CGFloat
    /// View Properties
    @State private var progressBar: UIProgressView?
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if let currentController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController,
               let alertController = currentController.presentedViewController as? UIAlertController
            {
                addProgressBar(alertController)
            }
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {
        if let progressBar {
            progressBar.progress = Float(progress)
            progressBar.tintColor = UIColor(config.tint)
        }
    }

    private func addProgressBar(_ controller: UIAlertController) {
        let progressView = UIProgressView()
        progressView.tintColor = UIColor(config.tint)
        progressView.progress = Float(progress)
        progressView.translatesAutoresizingMaskIntoConstraints = false // without this the view messed up

        let padding: CGFloat = isiOS26OrLater ? 30 : 15

        controller.view.addSubview(progressView)

        /// Constraints
        progressView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: padding).isActive = true
        progressView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -padding).isActive = true

        /// Offset
        var offset = config.fallbackOffset
        /// align progress view based on the current view location
        if !config.forceFallback {
            if let contentView = controller.view.allDescendants().first(where: {
                String(describing: type(of: $0)).contains("GroupHeaderScrollView")
            }) {
                offset = contentView.frame.height - (isiOS26OrLater ? 8 : 20)
            }
        }
        progressView.topAnchor
            .constraint(equalTo: controller.view.topAnchor, constant: offset).isActive = true
        progressBar = progressView
    }

    static func dismantleUIView(_: UIView, coordinator _: ()) {
        debugPrint("tear down called")
    }
}
