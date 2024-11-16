//
//  ExpandableSlideriOS18View.swift
//  animation

import SwiftUI

struct ExpandableSlideriOS18DemoView: View {
    @State private var volume: CGFloat = 30
    var body: some View {
        NavigationStack {
            VStack {
                CustomExpandableSlider(value: $volume, in: 0...100) {
                    /// Overlay view of image and text
                    HStack {
                        Image(systemName: "speaker.wave.3.fill", variableValue: volume / 100)
                        Spacer(minLength: 0)
                        Text(String(format: "%1.f", volume) + "%")
                            .font(.callout)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(15)
            .navigationTitle("Expandable slider")
        }
    }
}

struct CustomExpandableSlider<Overlay: View>: View {
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat>
    var config: Config
    var overlay: Overlay
    
    init(
        value: Binding<CGFloat>,
        in range: ClosedRange<CGFloat>,
        config: Config = .init(),
        @ViewBuilder overlay: @escaping () -> Overlay) {
        self._value = value
        self.range = range
        self.config = config
        self.overlay = overlay()
        self.lastStoredValue = value.wrappedValue
    }
    
    ///View Properties
    @State private var lastStoredValue: CGFloat
    @GestureState private var isActive: Bool = false

    var body: some View {
        GeometryReader {
            let size = $0.size
            let width = (value / range.upperBound) * size.width
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(config.inActiveTint)
                
                Rectangle()
                    .fill(config.activeTint)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: width)
                    }
                
                ZStack(alignment: .leading) {
                    overlay
                        .foregroundStyle(config.overlayInActiveTint)
                    
                    overlay
                        .foregroundStyle(config.overlayActiveTint)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: width)
                        }
                }
                .compositingGroup() /// group the view to a single view
                .animation(.easeInOut(duration: 0.3).delay(isActive ? 0.12 : 0).speed(isActive ? 1 : 2)) { /// adding delay to make animation and opacity smoother
                    $0
                    .opacity(isActive ? 1 : 0)
                }
            }
            .clipShape(.rect(cornerRadius: config.cornerRadius))
            .contentShape(.rect(cornerRadius: config.cornerRadius))
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isActive) { _, out, _ in
                        out = true
                    }
                    .onChanged { value in
                        let progress = ((value.translation.width / size.width) * range.upperBound) + lastStoredValue
                        self.value = max(min(progress, range.upperBound), range.lowerBound)
                    }.onEnded { _ in
                        lastStoredValue = value
                    }
            )
        }
        .frame(height: 20 + config.extraHeight)
        .mask { /// instead of directly change view size during expand, use mask to guarantee a smooth effect while user interacts the slider
            RoundedRectangle(cornerRadius: config.cornerRadius)
                .frame(height: 20 + (isActive ? config.extraHeight : 0))
        }
        .animation(.snappy, value: isActive)
    }
    
    struct Config {
        var activeTint: Color = Color.primary
        var inActiveTint: Color = .black.opacity(0.06)
        var cornerRadius: CGFloat = 15
        var extraHeight: CGFloat = 25
        /// Overlay Properties
        var overlayActiveTint: Color = .white
        var overlayInActiveTint: Color = .black
    }
}

#Preview {
    ExpandableSlideriOS18DemoView()
}
