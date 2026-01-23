//
//  TextFieldMicroInteractionView.swift
//  animation
//
//  Created on 1/22/26.
import SwiftUI

struct TextFieldMicroInteractionDemoView: View {
    @State private var message: String = ""
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {}
                .navigationTitle("Demo")
                .safeAreaInset(edge: .bottom) {
                    ChatBottomBar(message: $message) {} onRecordingStart: {} onRecordingFinished: { _ in
                    }
                    .padding(.horizontal, 15)
                }
        }
    }
}

struct ChatBottomBar: View {
    var hint: String = "Type your message..."
    @Binding var message: String
    var sendMessage: () -> Void
    var onRecordingStart: () -> Void
    var onRecordingFinished: (_ discarded: Bool) -> Void
    var addMenu: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Button(action: addMenu) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary)

                    TextField(hint, text: $message, axis: .vertical)
                        .lineLimit(5)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(.ultraThinMaterial, in: .capsule)

                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.blue.gradient, in: .circle)
                    .gesture(sendMessageGesture, isEnabled: !message.isEmpty)
            }
        }
    }

    var sendMessageGesture: some Gesture {
        TapGesture(count: 1).onEnded { _ in
            sendMessage()
        }
    }
}

#Preview {
    TextFieldMicroInteractionDemoView()
}
