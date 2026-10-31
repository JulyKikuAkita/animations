//
//  AppIconPickerDemo.swift
//  animation
//
//  Created on 10/31/26.
import SwiftUI

@available(iOS 26.0, *)
struct AppIconPickerDemo: View {
    @State private var showPicker: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Change App Icon") {
                    showPicker.toggle()
                }
            }
            .navigationTitle("App Icon Picker")
            .appIconPicker(isPresented: $showPicker) {
                Image(.defaultIconThumbnail)
            } alternateIconThumbnail: { iconName in
                let themeName = iconName.replacingOccurrences(of: "Doge-", with: "")
                Image("\(themeName)-Icon-Thumbnail")
            } alternateIconTitle: { iconName in
                Text(iconName.replacingOccurrences(of: "Doge-", with: ""))
            }
        }
    }
}

@available(iOS 26.0, *)
extension View {
    func appIconPicker(
        isPresented: Binding<Bool>,
        @ContentBuilder primaryIconThumbnail: @escaping () -> Image,
        @ContentBuilder alternateIconThumbnail: @escaping (_ iconName: String) -> Image,
        @ContentBuilder alternateIconTitle: @escaping (_ iconName: String) -> Text
    ) -> some View {
        sheet(isPresented: isPresented) {
            AppIconPicker(
                primaryIconThumbnail: primaryIconThumbnail,
                alternateIconThumbnail: alternateIconThumbnail,
                alternateIconTitle: alternateIconTitle
            )
        }
    }
}

@available(iOS 26.0, *)
private struct AppIconPicker: View {
    @ContentBuilder var primaryIconThumbnail: Image
    @ContentBuilder var alternateIconThumbnail: (_ iconName: String) -> Image
    @ContentBuilder var alternateIconTitle: (_ iconName: String) -> Text
    /// View Properties
    @State private var activeIcon: String? = "Primary"
    @State private var iconsList: [String] = Bundle.main.iconList
    @State private var scrollOffset: CGFloat = .zero
    @Environment(\.dismiss) private var dismiss

    var activeSystemIcon: String {
        UIApplication.shared.alternateIconName ?? "Primary"
    }

    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let iconSize = size.height * 0.5

                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            // primary icon
                            iconView("", isPrimary: true, iconSize: iconSize)
                                .id("Primary")

                            ForEach(iconsList, id: \.self) { icon in
                                iconView(icon, isPrimary: icon == "Doge-Default", iconSize: iconSize)
                                    .id(icon)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                    .scrollPosition(id: $activeIcon)
                    .safeAreaPadding(.horizontal, (size.width - iconSize) / 2)
                    .overlay(alignment: .top) {
                        indicatorView()
                    }
                    .overlay(alignment: .bottom) {
                        iconTitleView(iconSize)
                    }
                    .onScrollGeometryChange(for: CGFloat.self) {
                        $0.contentOffset.x + $0.contentInsets.leading
                    } action: { _, newValue in
                        scrollOffset = newValue
                    }
                }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                bottomBar()
            }
            .overlay(alignment: .topLeading) {
                // close button
                Button(role: .close) {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 20, height: 30)
                }
                .buttonStyle(.glass)
            }
            .safeAreaPadding(15)
            .ignoresSafeArea(.all, edges: .bottom)
            .presentationDetents([.height(400)])
            .presentationCompactAdaptation(.sheet)
            .onAppear {
                if activeIcon == nil {
                    activeIcon == activeSystemIcon
                }
            }
    }

    private func bottomBar() -> some View {
        let isActive = activeIcon == activeSystemIcon
        return VStack(spacing: 15) {
            Text("Set an icon for the app. Change as you go.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                // Primary icon means default icon, thus value nil
                UIApplication.shared.setAlternateIconName(activeIcon == "Primary" ? nil : activeIcon) { _ in
                    // dismiss view if icon is set successfully
                    dismiss()
                }
            } label: {
                Text(isActive ? "In Use" : "Activate App Icon")
                    .contentTransition(.numericText())
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .disabled(isActive)
            .animation(.easeInOut(duration: 0.2), value: isActive)
            .padding(.bottom, 10)
            .padding(.top, 5)
        }
        .padding(.horizontal, 15)
    }

    private func iconView(_ icon: String, isPrimary: Bool, iconSize: CGFloat) -> some View {
        ZStack {
            if isPrimary {
                primaryIconThumbnail
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                alternateIconThumbnail(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: iconSize, height: iconSize)
        .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.225, style: .continuous))
        .visualEffect { content, proxy in
            let minX = proxy.frame(in: .scrollView).minX
            let progress = min(abs(minX / iconSize), 1)
            let angle = iconSize / 3

            return content
                .scaleEffect(1 - (progress * 0.3))
                .blur(radius: progress * 4)
                .offset(x: minX / 2)
                .rotationEffect(.init(degrees: progress * angle))
        }
    }

    @ContentBuilder
    private func indicatorView() -> some View {
        let icons = ["Primary"] + iconsList
        let index = icons.firstIndex(of: activeIcon ?? "") ?? 0

        HStack(alignment: .bottom, spacing: 2) {
            Text(String(format: "%02d", index + 1))
                .font(.title3.bold())
                .foregroundStyle(.tint)
                .contentTransition(.numericText(value: Double(index)))

            Group {
                Text("/")
                Text(String(format: "%02d", icons.count))
            }
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
        }
        .monospaced()
        .animation(.easeInOut(duration: 0.25), value: activeIcon)
        .offset(y: 3)
    }

    @ContentBuilder
    private func iconTitleView(_ iconSize: CGFloat) -> some View {
        let icons = ["Primary"] + iconsList
        let scrollProgress = scrollOffset / iconSize

        ZStack {
            ForEach(icons.indices, id: \.self) { index in
                let icon = icons[index]
                let progress = scrollProgress - CGFloat(index)
                let cappedProgress = abs(progress)

                alternateIconTitle(icon)
                    .font(.title2.bold())
                    .offset(x: progress * -150)
                    .opacity(1 - (cappedProgress * 2))
            }
        }
        .offset(y: -25)
    }
}

/// Extracting all available alternative app icons vis bundle
/// App icon source settings should include all app icon assets
private extension Bundle {
    var iconList: [String] {
        let icons = infoDictionary?["CFBundleIcons"] as? [String: Any]
        let alternateIcons = icons?["CFBundleAlternateIcons"] as? [String: Any]
        return alternateIcons?.keys.sorted() ?? []
    }
}

@available(iOS 26.0, *)
#Preview {
    AppIconPickerDemo()
}
