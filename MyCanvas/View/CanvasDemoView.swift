//
//  CanvasDemoView.swift
//  MyCanvas
//
//  Created on 10/13/25.

import PaperKit
import PhotosUI
import SwiftUI

struct CanvasDemoView: View {
    @State private var data = EditorData()
    @State private var showTools: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            EditorView(
                size: .init(width: 350, height: 670),
                data: data
            )
            .toolbar {
                menuItems()

                Button("Export", systemImage: "square.and.arrow.up.fill") {
                    Task {
                        let rect = CGRect(
                            origin: .zero,
                            size: .init(width: 350, height: 670)
                        )
                        if let image = await data.exportAsImage(rect, scale: 1) {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }
                }

                Button("Size") {
                    Task {
                        if let markupData = await data.exportAsData() {
                            debugPrint(markupData)
                        }
                    }
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                guard let data = try? await newValue.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else {
                    return
                }
                self.data
                    .insertImage(image,
                                 rect: .init(origin: .zero, size: .init(width: 100, height: 100)))
                photoItem = nil
            }
        }
    }

    func menuItems() -> some View {
        Menu("Tools") {
            Button("Text") {
                data.insertText(.init("Hello World"), rect: .zero)
            }

            Menu("Shape") {
                let rect = CGRect(
                    origin: .zero,
                    size: .init(width: 100, height: 100)
                )

                Button("Rectangle") {
                    let config = ShapeConfiguration(
                        type: .roundedRectangle,
                        fillColor: UIColor.brown.cgColor
                    )
                    data.insertShape(config, rect: rect)
                }

                Button("Star") {
                    let config = ShapeConfiguration(
                        type: .star,
                        fillColor: UIColor.yellow.cgColor
                    )
                    data.insertShape(config, rect: rect)
                }
            }

            Button("Image") {
                showImagePicker.toggle()
            }

            Button(showTools ? "Hide" : "Show") {
                showTools.toggle()
                /// this add full pencil kit
                data.showPencilKits(showTools)
                /// this add only pencils
                // data.showPencils(showTools)
            }
        }
    }
}

#Preview {
    CanvasDemoView()
}
