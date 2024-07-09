//
//  ExpandableWheelPickerView.swift
//  animation

import SwiftUI

struct ExpandableWheelPickerView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

fileprivate struct CustomWheelPickerView: View {
    var texts: [String]
    @Binding var config: PickerConfig
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(texts, id: \.self) { text in
                        WheelTextView(text)
                    }
                }
            }
            /// pin the view to the mid up 20 cgpoint at the screen
            .safeAreaPadding(.top, (size.height * 0.5) - 20) /// -20 to position start point above center
            .safeAreaPadding(.bottom, (size.height * 0.5))
        }
    }
    
    @ViewBuilder
    private func WheelTextView(_ text: String) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            Text(text)
                .fontWeight(.semibold)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .trailing
                )
                .offset(x: -width * 0.3)
                .rotationEffect(
                    .init(degrees: rotation(proxy)),
                    anchor: .topTrailing
                )
        }
        .frame(height: 20)
        .lineLimit(1)
    }
    
    private func rotation(_ proxy: GeometryProxy) -> CGFloat {
        if let bounds = proxy.bounds(of: .scrollView(axis: .vertical)) {
            let height = bounds.height * 0.5
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            
            let maxRotation: CGFloat = 220 /// can be a custom value
            let progress = minY / height
            
            return progress * maxRotation
        }
        return 0
    }
}

#Preview {
    @Previewable
    @State var config = PickerConfig(text: "SwiftUI")
    let texts = ["SwiftUI", "UIKIT", "SwiftTest", "iOS", "macOS", "Xcode", "WWDC"]
    CustomWheelPickerView(texts: texts, config: $config)
}

extension View {
    @ViewBuilder
    func customWheelPicker(_ config: Binding<PickerConfig>, items: [String]) -> some View {
        self
            .overlay {
                if config.wrappedValue.show {
                    CustomWheelPickerView(texts: items, config: config)
                        .transition(.identity)
                }
            }
    }
}

struct PickerConfig {
    var text: String
    init(text: String) {
        self.text = text
    }
    var show: Bool = false
    /// for custom Matched Geometry Effect
    var sourceFrame: CGRect = .zero
}
