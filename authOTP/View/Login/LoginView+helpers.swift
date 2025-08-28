//
//  LoginView+helpers.swift
//  animation
//

import SwiftUI

/// disabled state until task is completed
struct TaskButton: View {
    var title: String
    var task: () async -> Void
    var onStatusChange: (Bool) -> Void = { _ in }
    @State private var isLoading: Bool = false
    var body: some View {
        Button {
            Task {
                isLoading = true
                await task()
                /// delay for task completed
                try? await Task.sleep(for: .seconds(0.1))
                isLoading = false
            }
        } label: {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .opacity(isLoading ? 0 : 1)
                .overlay {
                    ProgressView()
                        .opacity(isLoading ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .tint(.primary)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .disabled(isLoading)
        .onChange(of: isLoading) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) {
                onStatusChange(newValue)
            }
        }
    }
}

/// Custom icon field with background
struct IconTextField: View {
    var hint: String
    var symbol: String
    var isPassword: Bool = false
    @Binding var value: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundColor(.gray)
                .frame(width: 30)
            Group {
                if isPassword {
                    SecureField(hint, text: $value)
                } else {
                    TextField(hint, text: $value)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(.capsule)
        }
    }
}

extension View {
    func sheetAlert(
        isPresented: Binding<Bool>,
        prominentSymbol: String,
        title: String,
        message: String,
        primaryButtonTitle: String,
        primaryButtonAction: @escaping () async -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            VStack(spacing: 15) {
                Image(systemName: prominentSymbol)
                    .font(.system(size: 100))

                VStack(alignment: .center, spacing: 6) {
                    Text(title)
                        .lineLimit(1)

                    Text(message)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                TaskButton(title: primaryButtonTitle) {
                    await primaryButtonAction()
                }
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, isiOS26OrLater ? 20 : 10)
            .presentationBackground(.background)
            .presentationDetents([.height(270)])
            .presentationCornerRadius(isiOS26OrLater ? nil : 30)
            .ignoresSafeArea(isiOS26OrLater ? .all : [])
            .interactiveDismissDisabled()
        }
    }

    func customAlert(_ modal: Binding<AlertModal>) -> some View {
        sheetAlert(
            isPresented: modal.show,
            prominentSymbol: modal.wrappedValue.icon,
            title: modal.wrappedValue.title,
            message: modal.wrappedValue.message,
            primaryButtonTitle: "Done"
        ) {
            if let action = modal.wrappedValue.action {
                action()
            } else {
                modal.wrappedValue.show = false
            }
        }
    }
}

struct AlertModal {
    var icon: String = "exclamationmark.triangle.fill"
    var title: String = "Something went wrong."
    var message: String
    var show: Bool = false
    var action: (() -> Void)?
}
