//
//  DrawerButtonView.swift
//  animation
//
// each button apply to specific DrawerConfig
// do not apply multiple buttons to the same config
import SwiftUI

struct DrawerButtonDemoView: View {
    @State private var config: DrawerConfig = .init()

    var body: some View {
        NavigationStack {
            VStack {
                DrawerButton(title: "Continue", config: $config)
            }
            .padding(15)
            .navigationTitle("Drawer Button")
        }
        .alertDrawerOverlay(config: $config, primaryTitle: "Continue", secondaryTitle: "Cancel") {
            false
        } onSecondaryClick: {
            true
        } content: {
            /// placerholder
            VStack(alignment: .leading, spacing: 15) {
                Image(systemName: "exclamationmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Are you sure?")
                    .font(.title2.bold())

                Text("All unsaved content will be discard. Please make sure you have saved all your work.\nPlease press continue to proceed or cancel to go back.")
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300)
            }
        }
    }
}

struct DrawerButton: View {
    var title: String
    @Binding var config: DrawerConfig
    var body: some View {
        Button {
            config.hideSourceButton = true
            withAnimation(config.animation) {
                config.isPresented = true
            }
        } label: {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(config.tint, in: config.clipShape)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(config.hideSourceButton ? 0 : 1)
        // get source button frame information for animation
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: { newValue in
            config.sourceRect = newValue
        }
    }
}

struct DrawerConfig {
    var tint: Color = .red
    let foregroundColor: Color = .white
    let clipShape: AnyShape = .init(.capsule)
    let animation: Animation = .snappy(duration: 0.35, extraBounce: 0)

    fileprivate(set) var isPresented: Bool = false
    fileprivate(set) var hideSourceButton: Bool = false
    fileprivate(set) var sourceRect: CGRect = .zero
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.linear(duration: 0.2), value: configuration.isPressed)
    }
}

/// Overlay view to expand the alert drawer
/// the overlay appears on top of sheet/full screen cover
extension View {
    @ViewBuilder
    func alertDrawerOverlay(
        config: Binding<DrawerConfig>,
        primaryTitle: String,
        secondaryTitle: String,
        onPrimaryClick: @escaping () -> Bool,
        onSecondaryClick: @escaping () -> Bool,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GeometryReader { geometry in
                    let isPresented = config.wrappedValue.isPresented
                    let sourceRect = config.wrappedValue.sourceRect
                    ZStack {
                        if isPresented {
                            Rectangle()
                                .fill(.black.opacity(0.5))
                                .transition(.opacity)
                                .onTapGesture {
                                    withAnimation(config.wrappedValue.animation) {
                                        config.wrappedValue.isPresented = false
                                    } completion: {
                                        config.wrappedValue.hideSourceButton = false
                                    }
                                }
                        }

                        if config.wrappedValue.hideSourceButton {
                            AlertDrawerContent(
                                proxy: geometry,
                                primaryTitle: primaryTitle,
                                secondaryTitle: secondaryTitle,
                                onPrimaryClick: onPrimaryClick,
                                onSecondaryClick: onSecondaryClick,
                                config: config,
                                content: content
                            )
                            .transition(.identity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

private struct AlertDrawerContent<Content: View>: View {
    var proxy: GeometryProxy
    var primaryTitle: String
    var secondaryTitle: String
    var onPrimaryClick: () -> Bool
    var onSecondaryClick: () -> Bool
    @Binding var config: DrawerConfig
    @ViewBuilder var content: Content
    var body: some View {
        let isPresented = config.isPresented
        let sourceRect = config.sourceRect
        let maxY = proxy.frame(in: .global).maxY
        let bottomPadding: CGFloat = 10

        VStack(spacing: 15) {
            content
                .overlay(alignment: .topTrailing) {
                    Button {
                        dismissDrawer()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.primary, .gray.opacity(0.15))
                    }
                }
                .compositingGroup()
                .opacity(isPresented ? 1 : 0)

            /// Actions
            HStack(spacing: 10) {
                GeometryReader { geometry in
                    Button {
                        if onSecondaryClick() {
                            dismissDrawer()
                        }
                    } label: {
                        Text(secondaryTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.ultraThinMaterial, in: config.clipShape)
                    }
                    .offset(fixedLocation(geometry))
                    .opacity(isPresented ? 1 : 0)
                }
                .frame(height: config.sourceRect.height)

                GeometryReader { geometry in
                    Button {
                        if onPrimaryClick() {
                            dismissDrawer()
                        }
                    } label: {
                        Text(primaryTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(config.foregroundColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(config.tint, in: config.clipShape)
                    }
                    .frame(
                        width: isPresented ? nil : sourceRect.width,
                        height: isPresented ? nil : sourceRect.height
                    )
                    .offset(fixedLocation(geometry))
                }
                .frame(height: config.sourceRect.height)
                /// above the cancel button
                .zIndex(1)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding([.horizontal, .top], 20)
        .padding(.bottom, 15)
        .frame(
            width: isPresented ? nil : sourceRect.width,
            height: isPresented ? nil : sourceRect.height,
            alignment: .top
        )
        .background(.background)
        .clipShape(.rect(cornerRadius: sourceRect.height / 2))
        .shadow(color: .black.opacity(isPresented ? 0.1 : 0), radius: 5, x: 5, y: -5)
        .shadow(color: .black.opacity(isPresented ? 0.1 : 0), radius: 5, x: -5, y: -5)
        .padding(.horizontal, isPresented ? 20 : 0)
        .visualEffect { content, proxy in
            content
                .offset(
                    x: isPresented ? 0 : sourceRect.minX,
                    y: (isPresented ? maxY - bottomPadding : sourceRect.maxY) - proxy.size.height
                )
        }
        .allowsHitTesting(config.isPresented)
    }

    private func dismissDrawer() {
        withAnimation(config.animation, completionCriteria: .logicallyComplete) {
            config.isPresented = false
        } completion: {
            config.hideSourceButton = false
        }
    }

    private func fixedLocation(_ proxy: GeometryProxy) -> CGSize {
        let isPresented = config.isPresented
        let sourceRect = config.sourceRect

        return CGSize(
            width: isPresented ? 0 : (sourceRect.minX - proxy.frame(in: .global).minX),
            height: isPresented ? 0 : (sourceRect.minY - proxy.frame(in: .global).minY)
        )
    }
}

#Preview {
    DrawerButtonDemoView()
}
