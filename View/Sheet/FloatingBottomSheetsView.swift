//
//  FloatingBottomSheetsView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 15+ baseline. Compare with the iOS-26-styled siblings
//  ([[iOS26StyleFloatingSheet]], [[iOS26-bottomSheet]]) to see
//  what newer chrome adds.
//
//  Learning point
//  ──────────────
//  Two flavours of "floating" bottom sheet (sheet that visually
//  floats above the host instead of attaching to the screen edge):
//
//    1. **Alert-style** — fixed-height sheet with icon / title /
//       description / two buttons, wrapped in a custom
//       `.floatingBottomSheet` modifier exposed by this file.
//    2. **Free-form** — taller sheet with
//       `.presentationBackgroundInteraction` so the host's scroll
//       stays interactive while presented (Apple Maps style).
//
//  Both share the same chrome trick:
//  `.presentationBackground(.clear)` +
//  `.presentationDragIndicator(.hidden)` +
//  `.clipShape(.rect(cornerRadius:))` with `.compositingGroup()`
//  shadows to make the sheet a true rounded-rect floater rather
//  than the system's default edge-attached sheet.
//
//  The shadow-removal hack
//  ───────────────────────
//  `sheetShadowRemover` (UIViewRepresentable at the bottom of the
//  file) walks up to find the `_UIPresentationController` and
//  zeroes its shadow path. Without this, iOS draws an extra
//  drop-shadow under the sheet that conflicts with the rounded
//  floating chrome. Fragile UIKit reach-through — same risk
//  profile as `View/Alert/ProgressAlertDemoView.swift`'s
//  UIAlertController introspection.
//
//  Key APIs
//  ────────
//  • `.floatingBottomSheet(...)` — file-local View extension
//    bundling the chrome modifiers.
//  • `.presentationBackground(.clear)` + `.presentationCornerRadius(0)`
//    + `.presentationDragIndicator(.hidden)` — strip the system
//    sheet chrome.
//  • `.presentationDetents([.height(...), .fraction(0.999)])` —
//    fixed height + near-full alternative.
//  • `.presentationBackgroundInteraction(.enabled(upThrough:))` —
//    iOS 16+; user-interactive host content while sheet is
//    presented.
//
//  How to apply
//  ────────────
//  Reach for this when stock `.sheet` chrome looks too "system."
//  For iOS 26 visual polish, see [[iOS26StyleFloatingSheet]] —
//  same techniques composed into a reusable wrapper with an
//  `#available` fallback.
//
//  See also
//  ────────
//  • iOS26StyleFloatingSheet.swift — iOS 26 upgrade of the same
//    pattern with backwards-compat fallback.
//  • iOS26-bottomSheet.swift — Maps-style sheet + floating toolbar
//    responding to detent changes.
//  • iOS26ResizingSheet.swift — YouTube-Shorts-style sheet that
//    shrinks the underlying video as it expands.
//
import SwiftUI

struct FloatingBottomSheetsViewDemo: View {
    /// View Properties
    @State private var showStyle1: Bool = false
    @State private var showStyle2: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Show Style1") {
                    showStyle1.toggle()
                }

                Button("Show Style2") {
                    showStyle2.toggle()
                }
            }
            .navigationTitle("Floating Bottom Sheet")
        }
        .floatingBottomSheet(isPresented: $showStyle1) {
            FloatingBottomSheetsView(
                title: "Replace Existing Folder?",
                content: dummyDescription,
                image: .init(
                    content: "questionmark.folder.fill",
                    foreground: .white,
                    tint: .blue
                ),
                button1: .init(
                    content: "Replace",
                    foreground: .white,
                    tint: .blue
                ),
                button2: .init(
                    content: "Cancel",
                    foreground: Color.primary,
                    tint: Color.primary.opacity(0.08)
                )
            )
            .presentationDetents([.height(330)])
            /// demo the shadow area - by default sheet background has shadows even if set background to clear color
            /// this might be issue say as below example
            // .presentationBackgroundInteraction(.enabled(upThrough: .height(330)))
        }
        .floatingBottomSheet(isPresented: $showStyle2) {
            // need to define background color and shadow
            Text("Drag me up")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background.shadow(.drop(radius: 5)), in: .rect(cornerRadius: 25))
                .padding(.horizontal, 15)
                .padding(.top, 15)
                /// don't use .large, it will make the main view shrink, use fraction(0.999) instead
                .presentationDetents([.height(100), .height(330), .fraction(0.999)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(330)))
        }
    }
}

struct FloatingBottomSheetsView: View {
    var title: String
    var content: String
    var image: Config
    var button1: Config
    var button2: Config?
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: image.content)
                .font(.title)
                .foregroundStyle(image.foreground)
                .frame(width: 65, height: 65)
                .background(image.tint.gradient, in: .circle)

            Text(title)
                .font(.title3.bold())

            Text(content)
                .font(.callout)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.gray)

            buttonView(button1)

            if let button2 {
                buttonView(button2)
            }
        }
        .padding([.horizontal, .bottom], 15)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .padding(.top, 30)
        }
        .shadow(color: .black.opacity(0.12), radius: 8)
        .padding(.horizontal, 15)
    }

    func buttonView(_ config: Config) -> some View {
        Button {} label: {
            Text(config.content)
                .fontWeight(.bold)
                .foregroundStyle(config.foreground)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(config.tint.gradient, in: .rect(cornerRadius: 10))
        }
    }

    struct Config {
        var content: String
        var foreground: Color
        var tint: Color
    }
}

#Preview {
    FloatingBottomSheetsViewDemo()
}

/// Tip: the "floating sheet" recipe in 4 modifiers:
///   1. `.presentationCornerRadius(0)` — turn off the system rounded chrome so
///      our own clipShape on the inner content owns the corner radius.
///   2. `.presentationBackground(.clear)` — no system fill behind the sheet.
///   3. `.presentationDragIndicator(.hidden)` — kill the grabber pill.
///   4. `.background(SheetShadowRemover())` — strip the system drop shadow
///      via a `UIViewRepresentable` introspection pass (see below).
extension View {
    @ViewBuilder
    func floatingBottomSheet(
        isPresented: Binding<Bool>,
        onDismiss: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .presentationCornerRadius(0)
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .background(SheetShadowRemover())
        }
    }
}

/// Tip: UIKit introspection — fragile but powerful.
/// SwiftUI's `.sheet` adds an internal `_UIPresentationController` that draws
/// a drop shadow under the sheet's frame. There is no public API to disable
/// it, so we:
///   1. Insert this invisible `UIView` into the sheet's hierarchy (via
///      `.background(...)`).
///   2. Defer to the next runloop tick (`DispatchQueue.main.async`) so the
///      view has been added to its window.
///   3. Walk up the superview chain to the view directly under the `UIWindow`.
///   4. Clear `shadowColor` on every direct subview.
/// Same risk profile as any private-hierarchy reach-through — could break in
/// future iOS versions; revisit if shadows reappear.
private struct SheetShadowRemover: UIViewRepresentable {
    func updateUIView(_: UIViewType, context _: Context) {}

    func makeUIView(context _: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let uiSheetView = view.viewBeforeWindow {
                for view in uiSheetView.subviews {
                    /// clearing shadows
                    view.layer.shadowColor = UIColor.clear.cgColor
                }
            }
        }
        return view
    }
}

/// Tip: recursive walk up to the view sitting directly under the `UIWindow`.
/// Useful pattern for any modal-presentation introspection — sheets,
/// fullscreen covers, popovers all sit at this level.
private extension UIView {
    var viewBeforeWindow: UIView? {
        if let superview, superview is UIWindow {
            return self
        }

        return superview?.viewBeforeWindow
    }
}
