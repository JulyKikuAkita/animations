//
//  ProgressAlertDemoView.swift
//  animation
//
//  Created on 10/27/25.
// iOS 26
// find the UIAlertController and replace the default alert with a custom progress view
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
            if let contentView = controller.view.allSubViews().first(where: {
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
