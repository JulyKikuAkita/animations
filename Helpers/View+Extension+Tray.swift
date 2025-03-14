//
//  View+Tray.swift
//  animation
import SwiftUI

struct TrayConfig {
    var maxDetent: PresentationDetent
    var cornerRadius: CGFloat = 30
    var isInteractiveDismissDisabled: Bool = false
    var horizontalPadding: CGFloat = 15
    var bottomPadding: CGFloat = 15
}

extension View {
    @ViewBuilder
    func systemTrayView(
        _ show: Binding<Bool>,
        config: TrayConfig = .init(maxDetent: .fraction(0.99)),
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        sheet(isPresented: show) {
            content()
                .background(.background)
                .clipShape(.rect(cornerRadius: config.cornerRadius))
                .padding(.horizontal, config.horizontalPadding)
                .padding(.bottom, config.bottomPadding)
                .frame(maxHeight: .infinity, alignment: .bottom)
                /// Presentation configuration
                .presentationDetents([config.maxDetent])
                .presentationCornerRadius(0)
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(config.isInteractiveDismissDisabled)
                .background(RemoveSheetShadow())
        }
    }
}

private struct RemoveSheetShadow: UIViewRepresentable {
    func updateUIView(_: UIViewType, context _: Context) {}

    func makeUIView(context _: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let uiSheetView = view.dropShadowView {
                uiSheetView.layer.shadowColor = UIColor.clear.cgColor
            }
        }
        return view
    }
}

extension UIView {
    var dropShadowView: UIView? {
        if let superview, String(describing: type(of: superview)) == "UIDropShadowView" {
            return superview
        }
        return superview?.dropShadowView
    }
}
