//
//  PhotoPickeriMessageStyleDemoView.swift
//  animation
//
//  Created on 10/25/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 17+ for the `.sheet` detents; iOS 26 for the
//  `.onGeometryChange` keyboard-tracking branch.
//
//  Inline tips (preserved from the original header):
//    • When mixing a sheet with a TextField, sheets DON'T have a
//      `safeAreaBottom`, but the (default) keyboard view DOES
//      project a default `safeAreaBottom` on top — use a CUSTOM
//      keyboard, read its height, and apply the same height to
//      the sheet's `presentationDetents`.
//    • Single-line TextField → keyboard has a Return button.
//    • Multi-line TextField → no Return button; use
//      `scrollDismissesKeyboard(.interactively)` to dismiss.
//    • iOS 26: read the scroll-dismiss offset via `onGeometryChange`
//      and apply it to the bottom bar so the bar tracks the
//      keyboard mid-drag.
//    • The host ScrollView MUST NOT have `.ignoresSafeArea`, padding,
//      scale, or frame modifiers — those distort the offset value.
//
//  TODO: Cleanup
//        Line ~131: `.interactiveDismissDisabled() // not working
//        (still can pulldown photo views)` — the workaround for this
//        is the `DisableInteractiveDismissPreview` UIViewRepresentable
//        farther down. Add a one-line cross-reference comment so a
//        future reader connects them.
//
//  Learning point
//  ──────────────
//  iMessage-style chat composer that toggles a photo picker as a
//  bottom sheet WITHOUT losing the keyboard or the chat scroll
//  position. The whole demo is about coordinating three moving
//  parts that normally fight each other:
//    1. The chat `ScrollView` and its keyboard-aware bottom bar.
//    2. A `.sheet` (with `.presentationDetents([.height(...), .large])`)
//       containing `PhotosPicker(selection:matching:photoLibrary:)`
//       in its inline display style.
//    3. A keyboard-height observer (iOS 17 fallback via
//       `UIResponder.keyboardWillChangeFrameNotification`, iOS 26
//       via `onGeometryChange`) so the bar lifts cleanly with the
//       keyboard and the sheet's detent matches.
//
//  Why this is hard
//  ────────────────
//  iOS treats sheets and keyboards as INDEPENDENT presentation
//  surfaces. Dragging the keyboard down doesn't move a presented
//  sheet; presenting a sheet doesn't dismiss the keyboard. The
//  composite "drag down the keyboard, watch the photo picker rise
//  to fill the freed space" feel of iMessage requires manually
//  coordinating both — that's what this file demonstrates.
//
//  `DisableInteractiveDismissPreview` workaround
//  ─────────────────────────────────────────────
//  `interactiveDismissDisabled()` doesn't actually prevent pull-
//  to-dismiss when the sheet wraps a `PhotosPicker` — the picker's
//  inner `PHPickerViewController` still responds to its own pan.
//  The workaround is a `UIViewControllerRepresentable` that walks
//  up the responder chain to find the `PHPickerViewController` and
//  sets `isModalInPresentation = true`. Brittle; if Apple
//  restructures the picker's view hierarchy, the walk fails.
//
//  Key APIs
//  ────────
//  • `PhotosPicker(selection:matching:photoLibrary:)` (the inline
//    UI variant — different from `PhotosPickerItem`-based pickers
//    in [[ImagePicker]]).
//  • `.presentationDetents([.height(...), .large])` — fixed-
//    height detent matched to the keyboard height.
//  • `.scrollDismissesKeyboard(.interactively)` — drives the
//    drag-down-to-dismiss feel.
//  • `onGeometryChange(for: CGFloat.self)` (iOS 26) — keyboard
//    tracking via the scroll geometry, more reliable than
//    `keyboardWillChangeFrame` notifications.
//  • `UIResponder.keyboardWillChangeFrameNotification` (iOS < 26)
//    — the fallback path.
//  • `UIViewRepresentable` walking the responder chain to find
//    `PHPickerViewController` — the workaround above.
//
//  How to apply
//  ────────────
//  Use as a starting template whenever a chat/composer needs an
//  inline photo picker that doesn't disrupt typing. Copy the
//  detent/keyboard coordination wholesale; the photo-picker
//  workaround can stay or go depending on whether your sheet has
//  its own pull-to-dismiss UX.
//
//  See also
//  ────────
//  • ImagePicker.swift — simpler `PhotosPickerItem` flow without
//    the sheet/keyboard coordination.
//  • View/Keyboard/AnimatedKeyboard+iOS26.swift — different
//    keyboard-aware UI pattern using `safeAreaInset(edge: .bottom)`
//    + `ExpandableGlassMenuContainer`.
//
import PhotosUI
import SwiftUI

struct PickerInteractionProperties {
    var storedKeyboardHeight: CGFloat = 0
    var dragOffset: CGFloat = 0
    var showPhotoPicker: Bool = false
    var keyboardHeight: CGFloat {
        storedKeyboardHeight == 0 ? 300 : storedKeyboardHeight
    }

    @MainActor
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }

    @MainActor
    var screenSize: CGSize {
        if let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size {
            return size
        }
        return .zero
    }

    /// max animation duration <= 0.3 (default keyboard animation)
    var animation: Animation {
        Animation.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
    }
}

struct MockMessageView: View {
    @State private var properties: PickerInteractionProperties = .init()
    @State private var messageText: String = ""
    @State private var selectPhoto: PhotosPickerItem?
    @FocusState private var isKeyboardActive: Bool
    var body: some View {
        ScrollView(.vertical) {}
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 10) {
                bottomBar()
            }
            .ignoresSafeArea(.keyboard, edges: .all)
            .background {
                if #available(iOS 26, *) {
                    Rectangle()
                        .fill(.clear)
                        .onGeometryChange(for: CGFloat.self) {
                            $0.frame(in: .global).maxY
                        } action: { newValue in
                            guard properties.storedKeyboardHeight != 0 else { return }
                            let height = max(properties.screenSize.height - newValue - properties.safeArea.bottom, 0)
                            properties.dragOffset = properties.storedKeyboardHeight - height
                        }
                        .ignoresSafeArea(.container, edges: .all)
                }
            }
            .navigationTitle("Photo Picker")
            .toolbarTitleDisplayMode(.inlineLarge)
    }

    @ViewBuilder
    // swift:disable:function_body_length
    func bottomBar() -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Button {
                properties.showPhotoPicker.toggle()
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .animation(properties.animation) { content in
                        content
                            .rotationEffect(.init(degrees: properties.showPhotoPicker ? 45 : 0))
                    }
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: .circle)
                    .contentShape(.circle)
            }

            TextField("Message...", text: $messageText)
                .lineLimit(6) /// multiline text field
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 30))
                .focused($isKeyboardActive)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
        .geometryGroup()
        .padding(.bottom, animatedKeyboardHeight)
        .offset(y: isKeyboardActive ? properties.dragOffset : 0)
        .animation(properties.animation, value: animatedKeyboardHeight)
        /// Extracting Keyboard Height
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        ) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let height = frame.cgRectValue.height
                if properties.storedKeyboardHeight == 0 {
                    properties.storedKeyboardHeight = max(height - properties.safeArea.bottom, 0)
                }
            }
        }
        /// Photo picker
        .sheet(isPresented: $properties.showPhotoPicker) {
            PhotosPicker("", selection: $selectPhoto)
                .photosPickerStyle(.inline)
                .photosPickerDisabledCapabilities([.stagingArea, .sensitivityAnalysisIntervention])
                .presentationDetents([.height(properties.keyboardHeight), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(properties.keyboardHeight)))
                .interactiveDismissDisabled() // not working (still can pulldown photo views)
                .background(DisableInteractiveDismissPreview())
        }
        .onChange(of: properties.showPhotoPicker) { _, newValue in
            if newValue {
                isKeyboardActive = false
            }
            properties.dragOffset = 0
        }
        .onChange(of: isKeyboardActive) { _, newValue in
            if newValue {
                properties.showPhotoPicker = false
            }
            properties.dragOffset = 0
        }
    }

    var animatedKeyboardHeight: CGFloat {
        (properties.showPhotoPicker || isKeyboardActive) ? properties.keyboardHeight : 0
    }
}

/// Alternative w.a. when the .interactiveDismissDisabled() of photo sheet is not working
/// use UIViewRepresentable to locate PHPickerViewController and disable the interaction
struct DisableInteractiveDismissPreview: UIViewRepresentable {
    func makeUIView(context _: Context) -> some UIView {
        let view = UIView()
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let pickerController = view.viewController?.children.first as? PHPickerViewController {
                pickerController.isModalInPresentation = true
            }
        }
        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}
}

private extension UIView {
    var viewController: UIViewController? {
        sequence(first: self) { $0.next } // a sequence of responders
            .first(where: { $0 is UIViewController }) // return  Any of type UIResponder
            .flatMap { $0 as? UIViewController } // cast to type UIViewController
    }
}

#Preview {
    MockMessageView()
}
