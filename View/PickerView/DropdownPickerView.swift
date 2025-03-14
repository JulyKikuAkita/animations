//
//  DropdownPickerView.swift
//  animation

import SwiftUI

struct DropdownPickerDemoView: View {
    var pickerValues: [String] = ["Blue", "Green", "Red", "Orange", "Teal", "Swifty"]
    @State var config: DropdownConfig = .init(activeText: "Swifty")
    var body: some View {
        NavigationStack {
            List {
                DropdownPickerView(config: $config)
                    .listRowInsets(
                        .init(top: 0, leading: 0, bottom: 0, trailing: 0)
                    )
            }
            .navigationTitle("Dropdown")
        }
        .dropdownOverlay($config, values: pickerValues) /// place it in the root view
    }
}

private struct DropdownView: View {
    var values: [String]
    @Binding var config: DropdownConfig
    /// View Properties
    @State private var activeItem: String?
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ItemView(config.activeText)
                    .id(config.activeText)

                ForEach(filteredValues, id: \.self) { item in
                    ItemView(item)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.bottom, 200 - config.anchor.height)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $activeItem, anchor: .top)
        .scrollIndicators(.hidden)
        .frame(width: config.anchor.width, height: 200)
        .background(.background)
        .mask(alignment: .top) { /// animating view
            Rectangle()
                .frame(
                    /// if set height to 0, cause blinking when close showContent
                    height: config.showContent ? 200 : config.anchor.height,
                    alignment: .top
                )
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chevron.down")
                .rotationEffect(.init(degrees: config.showContent ? 180 : 0))
                .padding(.trailing, 15)
                .frame(height: config.anchor.height)
        }
        .clipShape(.rect(cornerRadius: config.cornerRadius))
        .offset(x: config.anchor.minX, y: config.anchor.minY)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background {
            if config.showContent {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .reverseMask(.topLeading) {
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .frame(width: config.anchor.width, height: 200)
                            .offset(x: config.anchor.minX, y: config.anchor.minY)
                    }
                    .transition(.opacity)
                    .onTapGesture {
                        closeDropdown(activeItem ?? config.activeText)
                    }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    func ItemView(_ item: String) -> some View {
        HStack {
            Text(item)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .frame(height: config.anchor.height)
        .contentShape(.rect)
        .onTapGesture {
            closeDropdown(item)
        }
    }

    func closeDropdown(_ item: String) {
        withAnimation(
            .easeInOut(duration: 0.35),
            completionCriteria: .logicallyComplete
        ) {
            activeItem = item
            config.showContent = false
        } completion: {
            config.activeText = item
            config.show = false
        }
    }

    var filteredValues: [String] {
        values.filter { $0 != config.activeText }
    }
}

/// Reverse masking
private extension View {
    @ViewBuilder
    func reverseMask(_ alignment: Alignment, @ViewBuilder content: @escaping () -> some View) -> some View {
        mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    content()
                        .blendMode(.destinationOut)
                }
        }
    }
}

/// Dropdown overlay
private extension View {
    @ViewBuilder
    func dropdownOverlay(_ config: Binding<DropdownConfig>, values: [String]) -> some View {
        overlay {
            if config.wrappedValue.show {
                DropdownView(values: values, config: config)
                    .transition(.identity)
            }
        }
    }
}

/// Source view
struct DropdownPickerView: View {
    @Binding var config: DropdownConfig
    var body: some View {
        HStack {
            Text(config.activeText)

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .background(.background, in: .rect(cornerRadius: config.cornerRadius))
        .contentShape(.rect(cornerRadius: config.cornerRadius))
        .onTapGesture {
            config.show = true
            withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
                config.showContent = true
            }
        }
        /// update source view anchor position to animate dropdown menu expanding
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: { newValue in
            config.anchor = newValue
        }
    }
}

struct DropdownConfig {
    var activeText: String
    var show: Bool = false
    var showContent: Bool = false /// animated the view when showup
    /// Source view properties
    var anchor: CGRect = .zero
    var cornerRadius: CGFloat = 10
}

#Preview {
    DropdownPickerDemoView()
}
