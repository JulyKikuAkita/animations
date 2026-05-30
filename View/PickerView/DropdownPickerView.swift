//
//  DropdownPickerView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Custom dropdown that grows out of a button: tap the trigger,
//  the menu unfolds downward over the underlying content with a
//  blurred backdrop, and the active selection is hidden from the
//  list (so the user can't pick what they already have). Closes on
//  tap-outside via the backdrop, with a height-based mask for the
//  unfold animation rather than a clip-rectangle.
//
//  Three pieces:
//    1. `DropdownPickerView` — the trigger button. Reports its frame
//       via `onGeometryChange` so the menu knows where to anchor.
//    2. `DropdownView` — the overlay menu itself. Uses a scroll view
//       with `.scrollPosition(id:)` so the menu opens scrolled to
//       the currently-selected item (small thing, big UX win on
//       long lists).
//    3. `DropdownConfig` — the shared state (`isExpanded`, anchor
//       frame, options).
//
//  The unfold animation
//  ────────────────────
//  Instead of clipping, the menu uses
//  `.mask(alignment: .top) { Rectangle().frame(height: maskHeight) }`
//  where `maskHeight` animates from 0 to the menu's intrinsic height.
//  Result: items appear to peel out from the trigger top-down, with
//  shadows + corners preserved (a clip would cut them).
//
//  Custom `reverseMask` extension
//  ──────────────────────────────
//  Defined inside this file. Uses `.blendMode(.destinationOut)` to
//  CUT a hole in the blurred backdrop where the trigger button sits,
//  so the trigger appears un-blurred while everything else dims.
//  Tiny utility worth lifting into the project's helpers folder.
//
//  Key APIs
//  ────────
//  • `onGeometryChange(for: CGRect.self)` — captures the trigger's
//    on-screen frame for menu anchoring.
//  • `.scrollPosition(id:)` + `.scrollTargetBehavior(.viewAligned(limitBehavior:))`
//    — opens scrolled to the active selection.
//  • `.mask(alignment: .top) { Rectangle().frame(height: ...) }`
//    — height-animated reveal that preserves shadows/corners.
//  • `.ultraThinMaterial` for the dimmed backdrop, with
//    `reverseMask` cutting through to keep the trigger crisp.
//  • `.snappy` animation curve — the unifying motion.
//
//  How to apply
//  ────────────
//  Reach for this when stock `.menu` style feels too system-y and
//  you want branded chrome. The reveal-via-mask trick generalises:
//  use it any time `.clipShape` would chop off shadows.
//
//  See also
//  ────────
//  • PickerStylesGesturesView.swift — different picker UX flavor;
//    composition not relation.
//  • TimePickerView.swift — `.wheel`-style picker for ranged
//    numeric input.
//
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
                itemView(config.activeText)
                    .id(config.activeText)

                ForEach(filteredValues, id: \.self) { item in
                    itemView(item)
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

    func itemView(_ item: String) -> some View {
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
