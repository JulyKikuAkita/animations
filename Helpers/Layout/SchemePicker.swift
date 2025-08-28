//
//  SchemePicker.swift
//  animation
//
// SwiftUI preferred color scheme modifier didn't work at Xcode 16 beta
// Use UIWindow to update it instead
import SwiftUI

enum AppScheme: String {
    case dark = "Dark"
    case light = "Light"
    case device = "Device"
}

struct SchemePreview: Identifiable {
    let id: UUID = .init()
    let image: UIImage?
    let text: String
}

struct SchemeHostView<Content: View>: View {
    var content: Content

    /// View Properties
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        /// load saved color scheme
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
            window.overrideUserInterfaceStyle = appScheme == .dark ? .dark : appScheme == .light ? .light : .unspecified
        }
    }

    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false
    @Environment(\.colorScheme) private var scheme
    @State private var schemePreviews: [SchemePreview] = []
    @State private var showSheet: Bool = false
    @State private var overlayWindow: UIWindow?
    var body: some View {
        content
            .sheet(isPresented: $showSheet, onDismiss: {
                schemePreviews = []
                showPickerView = false
            }, content: {
                SchemePickerView(previews: $schemePreviews)
            })
            .onChange(of: showPickerView) { _, newValue in
                if newValue {
                    generateSchemePreviews()
                } else {
                    showSheet = false
                }
            }
            .onAppear {
                if let scene = (
                    UIApplication.shared.connectedScenes.first as? UIWindowScene
                ), overlayWindow == nil {
                    let window = UIWindow(windowScene: scene)
                    window.backgroundColor = .clear
                    window.isHidden = false
                    window.isUserInteractionEnabled = false
                    let emptyController = UIViewController()
                    emptyController.view.backgroundColor = .clear

                    window.rootViewController = emptyController
                    overlayWindow = window
                }
            }
    }

    /// Generating scheme previews and then push the sheet view
    private func generateSchemePreviews() {
        Task {
            if let window = (
                UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow, schemePreviews.isEmpty
            {
                let size = window.screen.bounds.size
                let defaultStyle = window.overrideUserInterfaceStyle

                /// check UIView extension  function of image()
                let defaultSchemePreview = window.image(size)
                schemePreviews.append(
                    .init(
                        image: defaultSchemePreview,
                        text: scheme == .dark ? AppScheme.dark.rawValue : AppScheme.light.rawValue
                    )
                )

                showOverlayImageView(defaultSchemePreview) // avoid blink of black screen when switch colorScheme

                window.overrideUserInterfaceStyle = scheme.oppositeInterfaceStyle
                let otherSchemePreviewImage = window.image(size)

                schemePreviews.append(
                    .init(
                        image: otherSchemePreviewImage,
                        text: scheme == .dark ? AppScheme.light.rawValue : AppScheme.dark.rawValue
                    )
                )

                /// Maintain the order of light scheme -> dark scheme
                if scheme == .dark {
                    schemePreviews = schemePreviews.reversed()
                }
                /// Reset to default style
                window.overrideUserInterfaceStyle = defaultStyle
                /// wrap up snapshot task without UI glitch
                try? await Task.sleep(for: .seconds(0))

                removeOverlayImageView()

                showSheet = true
            }
        }
    }

    private func showOverlayImageView(_ image: UIImage?) {
        if overlayWindow?.rootViewController?.view.subviews.isEmpty ?? false {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit

            overlayWindow?.rootViewController?.view.addSubview(imageView)
        }
    }

    private func removeOverlayImageView() {
        overlayWindow?.rootViewController?.view.subviews.forEach {
            $0.removeFromSuperview()
        }
    }
}

private extension ColorScheme {
    var oppositeInterfaceStyle: UIUserInterfaceStyle {
        self == .dark ? .light : .dark
    }
}

/*
 To show preview of dark/light scheme, we need to take screenshot of each screen
 */
struct SchemePickerView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @Binding fileprivate var previews: [SchemePreview]
    @State private var localSchemeState: AppScheme = .device
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Appearance")
                .font(.title3.bold())

            Spacer(minLength: 0)

            GeometryReader { _ in
                HStack(spacing: 0) {
                    ForEach(previews) { preview in
                        schemeCardView([preview])
                    }

                    schemeCardView(previews)
                }
            }
        }
        .padding(20)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background {
            ZStack {
                Rectangle()
                    .fill(.background)

                Rectangle()
                    .fill(Color.primary.opacity(0.05))
            }
            .clipShape(.rect(cornerRadius: 20))
        }
        .padding(.horizontal, 15)
        .presentationDetents([.height(320)])
        .presentationBackground(.clear)
        .onChange(of: appScheme, initial: true) { _, newValue in
            localSchemeState = newValue
        }
        .animation(.easeInOut(duration: 0.25), value: appScheme)
    }

    @ViewBuilder
    fileprivate func schemeCardView(_ preview: [SchemePreview]) -> some View {
        VStack(spacing: 6) {
            if let image = preview.first?.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        if let secondImage = preview.last?.image, preview.count == 2 {
                            GeometryReader {
                                let width = $0.size.width / 2

                                Image(uiImage: secondImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .mask(alignment: .trailing) {
                                        Rectangle()
                                            .frame(width: width)
                                    }
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 15))
            }

            let text = preview.count == 2 ? "Device" : preview.first?.text ?? ""
            Text(text)
                .font(.caption)
                .foregroundStyle(.gray)

            ZStack {
                Image(systemName: "circle")

                if localSchemeState.rawValue == text {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.primary)
                        .transition(.blurReplace)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture {
            if preview.count == 2 {
                appScheme = .device
            } else {
                appScheme = preview.first?.text == AppScheme.dark.rawValue ? .dark : .light
            }

            updateScheme()
        }
    }

    private func updateScheme() {
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow {
            window.overrideUserInterfaceStyle = appScheme == .dark ? .dark : appScheme == .light ? .light : .unspecified
        }
    }
}
