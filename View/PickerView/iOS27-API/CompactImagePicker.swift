//
//  CompactImagePicker.swift
//  animation
//
//  Created on 10/23/26.
import PhotosUI
import SwiftUI

@available(iOS 27, *)
struct CompactMorphingPhotoPickerDemo: View {
    @State private var showPicker: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {}
                .navigationTitle("Messages")
                .safeAreaInset(edge: .bottom) {
                    GlassEffectContainer(spacing: 10) {
                        HStack(spacing: 10) {
                            CompactImagePickerIOS27(clipShape: .capsule, isPresented: $showPicker) {
                                HStack(spacing: 10) {
                                    Button {
                                        showPicker.toggle()
                                    } label: {
                                        Image(systemName: "plus")
                                            .foregroundStyle(.primary)
                                    }

                                    TextField("Type a message", text: .constant(""))
                                }
                                .padding(.horizontal, 15)
                                .frame(height: 44)
                            } onSelection: { _ in
                            }

                            Button {} label: {
                                Image(systemName: "paperplane")
                                    .frame(width: 20, height: 30)
                            }
                            .buttonStyle(.glassProminent)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 10)
                }
        }
    }
}

@available(iOS 27, *)
struct CompactImagePickerIOS27<Label: View, S: Shape>: View {
    var maxWidth: CGFloat = 320
    var clipShape: S
    @Binding var isPresented: Bool
    @ContentBuilder var label: Label
    var onSelection: (PhotosPickerItem) -> Void
    /// View Properties
    @State private var selection: PhotosPickerItem?
    @State private var expandPicker: Bool = false
    @State private var removeZoomTransition: Bool = false
    @Namespace private var namespace

    var body: some View {
        label
            .frame(maxWidth: .infinity)
            .clipShape(clipShape)
            .matchedTransitionSource(id: "P_SOURCE", in: namespace)
            .glassEffect(.regular.interactive(), in: clipShape)
            .popover(isPresented: $isPresented) {
                PhotosPicker("", selection: $selection, matching: .images)
                    .photosPickerStyle(.inline)
                    .photosPickerMetadataOptions([.removeLocation])
                    .photosPickerDisabledCapabilities(.collectionNavigation)
                    .photosPickerAccessoryVisibility(.hidden)
                    .presentationCompactAdaptation(.popover)
                    .frame(width: maxWidth, height: 250)
                    // Expand to full picker button
                    .overlay(alignment: .topTrailing) {
                        Button {
                            expandPicker.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                removeZoomTransition = true
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .frame(width: 20, height: 30)
                        }
                        .buttonStyle(.glass)
                        .padding(10)
                    }
                    .matchedTransitionSource(id: "P_C_SOURCE", in: namespace)
                    .navigationTransition(
                        removeZoomTransition ? AnyNavigationTransition(.automatic) :
                            AnyNavigationTransition(.zoom(sourceID: "P_SOURCE", in: namespace))
                    )
                    .fullScreenCover(isPresented: $expandPicker) {
                        PhotosPicker("", selection: $selection, matching: .images)
                            .photosPickerStyle(.inline)
                            .photosPickerMetadataOptions([.removeLocation])
                            .photosPickerDisabledCapabilities(.selectionActions)
                            .ignoresSafeArea()
                            .overlay(alignment: .topLeading) {
                                Button {
                                    expandPicker = false
                                    isPresented = false
                                    selection = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .frame(width: 20, height: 30)
                                }
                                .buttonStyle(.glass)
                                .padding(.leading, 15)
                            }
                            .navigationTransition(
                                removeZoomTransition ? AnyNavigationTransition(.automatic) :
                                    AnyNavigationTransition(.zoom(sourceID: "P_C_SOURCE", in: namespace))
                            )
                            .interactiveDismissDisabled()
                            .onDisappear {
                                removeZoomTransition = false
                            }
                    }
            }
            .onChange(of: selection) { _, newValue in
                guard let newValue else { return }
                onSelection(newValue)
                expandPicker = false
                isPresented = false
                selection = nil
            }
    }
}

@available(iOS 27, *)
#Preview {
    CompactMorphingPhotoPickerDemo()
}
