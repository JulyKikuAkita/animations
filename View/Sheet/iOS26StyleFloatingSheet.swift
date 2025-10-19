//
//  iOS26 Style sheet.swift
//  animation
//
import MapKit
import SwiftUI

struct FloatingSheetIOS26StyleDemo: View {
    /// View Properties
    @State private var showSheet: Bool = false
    @State private var showSheetNewStyle: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Button("Show Sheet") {
                    showSheet.toggle()
                }
                Button("Show iOS 26 Style Sheet") {
                    showSheetNewStyle.toggle()
                }
            }
            .navigationTitle("iOS 26 Style Sheet")
        }
        /// original shet style
        .sheet(isPresented: $showSheet) {
            Text("test")
                .presentationDetents([.height(100), .height(400), .fraction(0.99)])
        }
        .iOS26StyleSheet(
            minimalCornerRadius: 20,
            padding: 20,
            isPresented: $showSheetNewStyle
        ) {
            Text("iOS 26 style")
                .presentationDetents([.height(100), .height(400), .fraction(0.99)])
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .height(400))
                )
        }
    }
}

#Preview {
    FloatingSheetIOS26StyleDemo()
}

extension View {
    @ViewBuilder
    func iOS26StyleSheet(
        minimalCornerRadius: CGFloat, // required for touch ID device
        padding: CGFloat,
        isPresented: Binding<Bool>,
        @ViewBuilder sheetContent: @escaping () -> some View
    ) -> some View {
        modifier(
            StyleiOS26SheetModifier(
                minimalCornerRadius: minimalCornerRadius,
                padding: padding,
                isPresented: isPresented,
                sheetContent: sheetContent
            )
        )
    }
}

private struct StyleiOS26SheetModifier<SheetContent: View>: ViewModifier {
    var minimalCornerRadius: CGFloat
    var padding: CGFloat
    @Binding var isPresented: Bool
    @ViewBuilder var sheetContent: SheetContent

    /// View Properties
    @State private var progress: CGFloat = .zero
    @State private var storedHeight: CGFloat = .zero
    @State private var animationDuration: CGFloat = .zero
    @State private var deviceCornerRadius: CGFloat = .zero

    private func resetProgress() {
        progress = .zero
        storedHeight = .zero
        animationDuration = .zero
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: resetProgress) {
                if #available(iOS 26, *) {
                    sheetContent
                } else {
                    let padding = padding * (1 - progress)
                    let cornerRadius = deviceCornerRadius - padding
                    GeometryReader { _ in
                        sheetContent
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                    }
                    .compositingGroup()
                    .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
                    .background {
                        /// use any custom background if needed
                        RoundedRectangle(
                            cornerRadius: cornerRadius,
                            style: .continuous
                        )
                        .fill(.background)
                    }
                    .padding([.horizontal, .bottom], padding)
                    .animation(
                        .easeInOut(duration: animationDuration),
                        value: progress
                    )
                    .presentationCornerRadius(cornerRadius)
                    .presentationBackground(.clear)
                    .background(SheetHelper(cornerRadius: { radius in
                        deviceCornerRadius = max(radius, minimalCornerRadius)
                    }, height: { height in
                        /// adjust 0.7 to your need
                        let maxHeight = windowSize.height * 0.7
                        let progress = max(0, min(1, height.rounded() / maxHeight))
                        self.progress = progress

                        let diff = abs(height - storedHeight)
                        let duration = max(min(diff / 100, 0.25), 0)
                        if diff > 0, storedHeight != .zero {
                            animationDuration = duration
                        }
                        storedHeight = height
                    }))
                    /// use .all to ignore keybaord
                    .ignoresSafeArea(.container, edges: .bottom)
                    /// optional
                    .persistentSystemOverlays(.hidden)
                }
            }
    }

    private var windowSize: CGSize {
        if let screen = (
            UIApplication.shared.connectedScenes.first as? UIWindowScene
        )?.screen {
            return screen.bounds.size
        }
        return .zero
    }
}

/// Calculate sheet corner radius per each devices type
private struct SheetHelper: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if !context.coordinator.isShadowRemoved {
            DispatchQueue.main.async {
                if let shadowView = uiView.dropShadowView {
                    shadowView.layer.shadowColor = UIColor.clear.cgColor
                    context.coordinator.isShadowRemoved = true
                }
            }
        } else {
            debugPrint("Alread removed")
        }
    }

    var cornerRadius: (CGFloat) -> Void
    var height: (CGFloat) -> Void
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let layer = view.superview?.superview?.superview?.layer {
                cornerRadius(layer.cornerRadius)
            }
        }
        return view
    }

    /// We need the current sheet height to calculate progress value
    func updateUIView(_ proposal: ProposedViewSize, _ uiView: UIView, context _: Context) -> CGSize? {
        /// fallback to ger proper cornerRaidus  if makeUIView failed
        if let layer = uiView.superview?.superview?.superview?.layer {
            cornerRadius(layer.cornerRadius)
        }

        if let height = proposal.height {
            self.height(height)
        }
        return nil
    }

    /// when enabe sheet background interaction, there's unwanted shadow
    ///  check .presentationBackgroundInteraction(
    class Coordinator: NSObject {
        var isShadowRemoved: Bool = false
    }
}
