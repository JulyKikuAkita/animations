//
//  PhotoPickeriMessageStyleDemoView.swift
//  animation
//
//  Created on 10/25/25.
//  when mix sheet with textfield, need to be aware that sheet does not have safeAreaBottom but
//  (default) keyboard view has default safeAreaBottom on top
//  -> use custom keyboard and read it's height instead, apply the same height to sheet's detent
//
// single line  Textfield -> keyboard has a return button
// multiline textfield -> no button but use scrollDismissKeyboard modifier to dismiss the keyboard
// how to read scrollview dismiss offset updates? iOS26 -> use onGeometryReader to calculate the
// offset and apply it to the bottom bar.
// Note the scrollView should not have .ignoreSafeArea modifier, nor padding, scale. frame modifier
// to get the right offset value

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

    // swift:disable:function_body_length
    @ViewBuilder
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
