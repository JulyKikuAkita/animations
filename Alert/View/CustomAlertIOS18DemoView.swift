//
//  CustomAlertIOS18DemoView.swift
//  Alert
//
import SwiftUI

struct CustomAlertIOS18DemoView: View {
    @State private var showAlert = false
    var body: some View {
        NavigationStack {
            List {
                Button("Show Alert") {
                    showAlert.toggle()
                }
                .alert(isPresented: $showAlert) {
                    CustomDialog(
                        title: "Folder Name",
                        content: "Enter a file Name",
                        image: .init(content: "folder.fill.badge.plus", tint: .blue, foreground: .white),
                        button1: .init(content: "Save Folder", tint: .blue, foreground: .white, action: { _ in
                            showAlert = false
                        }),
                        button2: .init(content: "Cancel", tint: .red, foreground: .white, action: { _ in
                            showAlert = false
                        }),
                        addsTextField: true,
                        textFieldHint: "Documents"
                    )
                    /// custom alert view
//                    VStack(spacing: 15) {
//                        Text("Alert Demo View")
//                            .fontWeight(.semibold)
//                            .underline()
//
//                        Button("Dismiss") {
//                            showAlert.toggle()
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .tint(.blue)
//                        .buttonBorderShape(.roundedRectangle(radius: 10))
//                    }
//                    .padding(15)
//                    .background(.background, in: .rect(cornerRadius: 10))
                    .transition(.blurReplace.combined(with: .push(from: .bottom))) /// allowed when using if condition to add view
                } background: {
                    Rectangle()
                        .fill(.primary.opacity(0.35))
                }
            }
            .navigationTitle("Custom Alert iOS 18")
        }
//        .overlay {
//            CustomDialog(
//                title: "Folder Name",
//                content: "Enter a file Name",
//                image: .init(content: "folder.fill.badge.plus", tint: .blue, foreground: .white),
//                button1: .init(content: "Save Folder", tint: .blue, foreground: .white, action: { folder in
//
//                }),
//                button2: .init(content: "Cancel", tint: .red, foreground: .white),
//                addsTextField: true,
//                textFieldHint: "Documents"
//            )
//        }
    }
}

struct CustomDialog: View {
    var title: String
    var content: String?
    var image: Config
    var button1: Config
    var button2: Config?
    var addsTextField: Bool = false
    var textFieldHint: String = ""
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: image.content)
                .font(.title)
                .foregroundStyle(image.foreground)
                .frame(width: 65, height: 65)
                .background(image.tint.gradient, in: .circle)
                .background {
                    Circle()
                        .stroke(.background, lineWidth: 8)
                }

            Text(title)
                .font(.title3.bold())

            if let content {
                Text(content)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.gray)
                    .padding(.vertical, 4)
            }

            if addsTextField {
                TextField(textFieldHint, text: $text)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.gray.opacity(0.1))
                    }
                    .padding(.bottom, 5)
            }

            ButtonView(button1)

            if let button2 {
                ButtonView(button2)
                    .padding(.top, -5)
            }
        }
        .padding([.horizontal, .bottom], 15)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .padding(.top, 30)
        }
        .frame(maxWidth: 310)
        .compositingGroup()
    }

    @ViewBuilder
    private func ButtonView(_ config: Config) -> some View {
        Button {
            config.action(addsTextField ? text : "")
        } label: {
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
        var tint: Color
        var foreground: Color
        var action: (String) -> Void = { _ in }
    }
}

#Preview {
    CustomAlertIOS18DemoView()
}
