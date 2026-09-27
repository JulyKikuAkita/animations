//
//  DuoVerticalConftrol.swift
//  animation
//
//  Created on 9/22/26.

import MapKit
import SwiftUI

@available(iOS 26.0, *)
struct DuoVerticalControlDemo: View {
    @State private var activeMode: MapMode = .explore
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(initialPosition: .region(.applePark))
                .mapStyle(.standard)
            VStack(alignment: .trailing) {
                HStack(alignment: .bottom) {
                    VerticalSCByPicker(selection: $activeMode)
                    VerticalSCByUIKit(selection: $activeMode)
                }
                Text("Active Mode: \(activeMode.rawValue)")
                    .background(.orange.gradient)
            }
        }
        .padding()
    }
}

/// Simplest vertical segment control with picker
/// no custom tint color/transparent
struct VerticalSCByPicker<Value: VerticalItem>: View {
    var pointSize: CGFloat = 18
    @Binding var selection: Value
    @Environment(\.displayScale) private var displayScale
    var body: some View {
        let itemWidth: CGFloat = 50
        let itemHeight: CGFloat = 60
        let pickerHeight = CGFloat(Value.allCases.count) * itemHeight

        Picker("", selection: $selection) {
            ForEach(Array(Value.allCases), id: \.symbol) { item in
                let config = UIImage.SymbolConfiguration(pointSize: pointSize)
                if let cgImage = UIImage(systemName: item.symbol)?
                    .withConfiguration(config).cgImage
                {
                    Image(
                        decorative: cgImage,
                        scale: displayScale,
                        orientation: .left
                    )
                    .tag(item)
                }
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.large)
        .frame(width: pickerHeight, height: itemWidth)
        .rotationEffect(.init(degrees: 90)) // turn vertical
        .frame(width: itemWidth, height: pickerHeight)
    }
}

/// fullycontrol vertical segement
@available(iOS 26.0, *)
struct VerticalSCByUIKit<Value: VerticalItem>: View {
    var tint: Color = .pink.opacity(0.3)
    var pointSize: CGFloat = 18
    @Binding var selection: Value
    var body: some View {
        let itemWidth: CGFloat = 50
        let itemHeight: CGFloat = 60
        let pickerHeight = CGFloat(Value.allCases.count) * itemHeight

        VerticalSegmentedScView(
            pointSize: pointSize,
            tint: tint,
            selection: $selection
        )
        .rotationEffect(.init(degrees: 90)) // turn vertical
        .frame(width: itemWidth, height: pickerHeight)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

private struct VerticalSegmentedScView<Value: VerticalItem>: UIViewRepresentable {
    var pointSize: CGFloat
    var tint: Color
    @Binding var selection: Value
    @Environment(\.displayScale) private var displayScale

    func makeUIView(context: Context) -> UISegmentedControl {
        let items: [UIImage] = Value.allCases.compactMap { item in
            let config = UIImage.SymbolConfiguration(pointSize: pointSize)
            guard let cgImage = UIImage(systemName: item.symbol)?
                .withConfiguration(config).cgImage
            else { return nil }
            return UIImage(
                cgImage: cgImage,
                scale: displayScale,
                orientation: .left
            )
        }

        let control = UISegmentedControl(items: items)
        control.selectedSegmentTintColor = UIColor(tint)
        control.selectedSegmentIndex = Array(Value.allCases)
            .firstIndex(of: selection) ?? 0
        control.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.valueChanged(_:)),
            for: .valueChanged
        )

        DispatchQueue.main.async {
            removeBackgroundColor(control)
        }
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context _: Context) {
        let index = Array(Value.allCases).firstIndex(of: selection) ?? 0
        if uiView.selectedSegmentIndex != index {
            uiView.selectedSegmentIndex = index
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    class Coordinator: NSObject {
        @Binding var selection: Value
        init(selection: Binding<Value>) {
            _selection = selection
        }

        @MainActor @objc func valueChanged(_ sender: UISegmentedControl) {
            selection = Array(Value.allCases)[sender.selectedSegmentIndex]
        }
    }

    private func removeBackgroundColor(_ control: UISegmentedControl) {
        for subview in control.subviews {
            if subview is UIImageView, subview != control.subviews.last {
                subview.alpha = 0
            }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        let size = proposal.replacingUnspecifiedDimensions()
        // flipping the contents
        return .init(width: size.height, height: size.width)
    }
}

@available(iOS 26.0, *)
#Preview {
    DuoVerticalControlDemo()
}
