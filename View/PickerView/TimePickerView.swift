//
//  TimePickerView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cleanup — DUPLICATE-DIVERGENT FILE
//        An identically-named file at
//        `PomodoroFocusTimer/TimePickerView.swift` defines THE SAME
//        struct names: `TimePickerDemoView`, `TimePickerView`,
//        `PickerViewWithoutIndicator`. They likely live in different
//        Xcode targets (so no compile collision), but they're
//        parallel implementations that will drift apart silently.
//        Either:
//          (a) Consolidate into one Helpers/ file shared by both
//              targets, or
//          (b) Add target prefixes (e.g. `PomodoroTimePickerView`)
//              so future maintainers can grep without confusion.
//
//  TODO: Cleanup — UIPickerView internals
//        Lines ~79–80 reach into UIPickerView's subview hierarchy
//        ("trial and error and found 2nd subview contained the bg")
//        to clear the picker's default background. Private-
//        implementation-detail trap; Apple may renumber subviews in
//        any iOS update. Same risk profile as
//        `View/Alert/ProgressAlertDemoView.swift`'s UIAlertController
//        introspection. Migrate to a fully-custom wheel (similar to
//        [[ExpandableWheelPickerView]]) when the hack breaks.
//
//  Learning point
//  ──────────────
//  Hours/minutes/seconds wheel picker built from three side-by-side
//  `Picker(.wheel)` columns. Two practical bits worth understanding:
//
//    1. **Indicator removal** via `RemovePickerIndicator`
//       (`UIViewRepresentable` at the bottom of the file). Walks
//       the responder chain from a no-op host UIView up to the
//       enclosing `UIPickerView` and clears its 2nd subview's
//       background — that's the rounded-rect "selection
//       indicator" Apple draws by default. The cleared indicator
//       is what makes a custom-styled time picker look integrated
//       rather than "stock UIPickerView under custom chrome."
//    2. **`PickerViewWithoutIndicator<Content, Selection>`** — the
//       generic wrapper that bundles the indicator removal with a
//       standard `Picker(_:selection:)`. Reusable anywhere a flat-
//       styled wheel is wanted.
//
//  Why three Pickers instead of one composite?
//  ───────────────────────────────────────────
//  SwiftUI's `Picker(.wheel)` is single-column. Multi-column wheels
//  (like the system date picker) are bespoke UIKit controls that
//  don't have a SwiftUI peer. Three columns side by side, each
//  binding a separate `@State Int`, is the simplest path.
//
//  Key APIs
//  ────────
//  • `Picker(_:selection:).pickerStyle(.wheel)` — single-column
//    wheel; one per HMS unit.
//  • `UIViewRepresentable` walking the responder chain — the
//    UIKit reach-through to find the enclosing `UIPickerView`.
//  • `pickerView` recursive extension property — converts
//    `UIView → UIPickerView` by walking `superview` until a
//    matching ancestor is found.
//  • `DispatchQueue.main.async { ... }` — defers the subview-
//    background clear until after the picker has finished initial
//    layout (otherwise the cleared layer gets re-drawn).
//
//  How to apply
//  ────────────
//  Use for any "duration / time-of-day" entry that needs custom
//  styling. For wholly custom wheel UX without UIKit, see
//  [[ExpandableWheelPickerView]] or [[CircularWheelPicker]] —
//  SwiftUI-native and free of the introspection trap.
//
//  See also
//  ────────
//  • PomodoroFocusTimer/TimePickerView.swift — the duplicate-
//    divergent sibling (see TODO above).
//  • CircularWheelPicker.swift, ExpandableWheelPickerView.swift —
//    SwiftUI-native wheel alternatives.
//
import SwiftUI

struct TimePickerDemoView: View {
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var seconds: Int = 25
    var body: some View {
        NavigationStack {
            VStack {
                TimePickerView(
                    hours: $hours,
                    minutes: $minutes,
                    seconds: $seconds
                )
            }
            .padding(15)
            .navigationTitle("Custom Time Picker")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray.opacity(0.15))
        }
    }
}

struct TimePickerView: View {
    var style: AnyShapeStyle = .init(.bar)
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        HStack(spacing: 0) {
            customView("hours", 0 ... 24, $hours)
            customView("mins", 0 ... 60, $minutes)
            customView("seconds", 0 ... 60, $seconds)
        }
        .offset(x: -25)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .frame(height: 35)
        }
    }

    @ViewBuilder
    private func customView(_ title: String, _ range: ClosedRange<Int>, _ selection: Binding<Int>) -> some View {
        PickerViewWithoutIndicator(selection: selection) {
            ForEach(range, id: \.self) { value in
                Text("\(value)")
                    .frame(width: 35, alignment: .trailing)
                    .tag(value)
            }
        }
        .overlay {
            Text(title)
                .font(.callout.bold())
                .frame(minWidth: 50, alignment: .leading)
                .lineLimit(1)
                .offset(x: 50)
        }
    }
}

#Preview {
    TimePickerDemoView()
}

/// Helpers
struct PickerViewWithoutIndicator<Content: View, Selection: Hashable>: View {
    @Binding var selection: Selection
    @ViewBuilder var content: Content
    @State private var isHidden: Bool = false

    var body: some View {
        Picker("", selection: $selection) {
            if !isHidden {
                RemovePickerIndicator {
                    isHidden = true
                }
            } else {
                content
            }
        }
        .pickerStyle(.wheel)
    }
}

private struct RemovePickerIndicator: UIViewRepresentable {
    var result: () -> Void
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let pickerView = view.pickerView {
                // trial and error and found 2nd subview contained the bg for the UIPicker view
                if pickerView.subviews.count >= 2 {
                    pickerView.subviews[1].backgroundColor = .clear
                }
                result()
            }
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}

private extension UIView {
    var pickerView: UIPickerView? {
        if let view = superview as? UIPickerView {
            return view
        }

        return superview?.pickerView
    }
}
