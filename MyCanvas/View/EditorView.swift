//
//  EditorView.swift
//  MyCanvas
//
//  Created on 10/13/25.

import PaperKit
import SwiftUI

struct EditorView: View {
    var size: CGSize
    @State var data: EditorData

    init(size: CGSize, data: EditorData) {
        self.size = size
        _data = .init(initialValue: data)
    }

    var body: some View {
        if let controller = data.controller {
            PaperControllerView(controller: controller)
        } else {
            ProgressView()
                .onAppear {
                    data.initializeController(.init(origin: .zero, size: size))
                }
        }
    }
}

private struct PaperControllerView: UIViewControllerRepresentable {
    var controller: PaperMarkupViewController
    func makeUIViewController(context _: Context) -> some UIViewController {
        controller
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}
