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
    /// View Properties
    @State private var activeText: String?
    @State private var showContents: Bool = false
    @State private var showScrollview: Bool = false
    @State private var expandItems: Bool = false
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(showContents ? 1: 0)
                .ignoresSafeArea()
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(texts, id: \.self) { text in
                        WheelTextView(text, size: size)
//                        LeadingSideWheelTextView(text, size: size)
                    }
                }
                .scrollTargetLayout() // required to sync with scroll position
            }
            /// pin the view to the mid up 20 CGPoint at the screen
            .safeAreaPadding(.top, (size.height * 0.5) - 20) /// -20 to position start point above center
            .safeAreaPadding(.bottom, (size.height * 0.5))
            .scrollPosition(id: $activeText, anchor: .center) /// anchor needs to be at center position because above
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollIndicators(.hidden)
            .opacity(showScrollview ? 1 : 0)
        }
        .task {
            /// Doing actions only for the first time
            guard activeText == nil else { return }
            activeText = config.text
            showScrollview = true
        }
        .onChange(of: activeText) { oldValue, newValue in
            if let newValue {
                config.text = newValue
            }
        }
        .onTapGesture {
            withAnimation(.snappy) {
                expandItems.toggle()
            }
        }
    }
    
    @ViewBuilder
    private func WheelTextView(_ text: String, size: CGSize) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(config.text == text ? .blue : .gray)
                .offset(y: offset(proxy))
                .opacity(expandItems ? 1 : config.text == text ? 1 : 0)
                .clipped() // avoid overlapping view
                .offset(x: -width * 0.3)
                .rotationEffect(
                    .init(degrees: expandItems ? -rotation(proxy, size) : .zero),
                    anchor: .topTrailing
                )
                .opacity(opacity(proxy, size))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .trailing
                )
        }
        .frame(height: 20)
        .lineLimit(1)
    }
    
    /// View Transition Helpers
    private func offset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return expandItems ? 0 : -minY
    }
    
    private func rotation(_ proxy: GeometryProxy, _ size: CGSize) -> CGFloat {
        let height = size.height * 0.5
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        
        let maxRotation: CGFloat = 220 /// can be a custom value
        let progress = minY / height
        
        return progress * maxRotation
    }
    
    private func opacity(_ proxy: GeometryProxy, _ size: CGSize) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let height = size.height * 0.5
        let progress = (minY / height) * 2.8 /// use 2.8 , 4 or any number fits
        /// make sure opacity value > 0
        let opacity = progress < 0 ? 1 + progress : 1 - progress
        return opacity
    }
    
    @ViewBuilder
    private func LeadingSideWheelTextView(_ text: String, size: CGSize) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            Text(text)
                .fontWeight(.semibold)
                .offset(x: width * 0.3)
                .rotationEffect(
                    .init(degrees: rotation(proxy, size)),
                    anchor: .topTrailing
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .leading
                )
        }
        .frame(height: 20)
        .lineLimit(1)
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
