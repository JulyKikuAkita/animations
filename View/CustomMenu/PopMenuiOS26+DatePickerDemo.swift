//
//  PopMenuiOS26+DatePickerDemo.swift
//  animation
//
//  Created on 9/24/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 26+ only — `@available(iOS 26.0, *)`. Gating APIs:
//  `.matchedTransitionSource` and `.navigationTransition(.zoom(...))`.
//
//  Inline tips (kept verbatim from the original header):
//    • Apply `matchedTransitionSource` BEFORE the glass effect, or
//      the transition clips the glass + shadows.
//    • Glass background is auto-applied during the transition; no
//      workaround needed.
//
//  Learning point
//  ──────────────
//  Popover-as-zoom: tap a button and instead of a flat popover
//  fade-in, the popover GROWS out of the button via the iOS 26
//  zoom transition. The button is the source; the popover is the
//  destination; matching them with `matchedTransitionSource(id:in:)`
//  on the source and `navigationTransition(.zoom(sourceID:in:))`
//  on the destination tells the system to animate the bounding
//  rect between the two.
//
//  Inside the popover: a date-range picker (`DateFilterDemoView`)
//  with two `DatePicker(.graphical)` panels. The popover uses
//  `.presentationCompactAdaptation(.popover)` so it stays a
//  popover even on compact (phone) widths instead of forcing a
//  sheet.
//
//  `CustomPopMenuiOS26` (reusable button)
//  ──────────────────────────────────────
//  Wraps the source-button + popover wiring into a one-line API:
//  caller passes a label, content, and tap handler; the helper
//  handles the namespace, transition source, and presentation.
//  Copy-paste this if you need the same effect on another button.
//
//  Key APIs
//  ────────
//  • `.matchedTransitionSource(id:in:)` — iOS 26. Marks a view as
//    the SOURCE of a zoom transition. The order of modifiers
//    matters here (see inline tip above).
//  • `.navigationTransition(.zoom(sourceID:in:))` — iOS 26. Marks
//    the destination; sourceID matches the source's id; namespace
//    must match too.
//  • `.popover(isPresented:)` — iOS 16+. The presentation surface;
//    iOS 26 lets it pick up the zoom transition automatically.
//  • `.presentationCompactAdaptation(.popover)` — keeps the popover
//    a popover on iPhone (vs. the default sheet adaptation).
//  • `.glassProminent` button style + `.sensoryFeedback(.impact)`
//    — iOS 26 chrome + haptic feedback.
//
//  How to apply
//  ────────────
//  Use whenever a button's popover content is closely tied to the
//  button itself (filter chip → filter editor, date label → date
//  picker, member chip → member detail). The zoom feels like the
//  button "opens up." For unrelated content, prefer a stock
//  popover.
//
//  See also
//  ────────
//  • View/Notifications/CustomNotificationsView.swift — different
//    iOS 26 transition (no zoom, but similar source-anchored
//    presentation feel).
//  • View/QRCode/DIRQScannerView.swift — also uses
//    `Transaction(disablesAnimations:)` + manual morph for a
//    fullScreenCover; compare the two strategies.
//
import SwiftUI

@available(iOS 26.0, *)
struct PopMenuiOS26DatePickerDemo: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 25) {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.gray.opacity(0.15))
                    .frame(height: 220)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transaction History")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("12 June 2025 - 20 Sep 2025")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    /// Custom Menu
                    CustomPopMenuiOS26(style: .glass) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .frame(width: 40, height: 30)
                    } content: {
                        DateFilterDemoView()
                    }
                }
            }
            .padding(15)
            .padding(.bottom, 700)
        }
    }
}

@available(iOS 26.0, *)
struct CustomPopMenuiOS26<Label: View, Content: View>: View {
    var style: CustomMenuStyleiOS26 = .glass
    var isHapticsEnabled: Bool = true
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content
    /// View Properties
    ///  Optional haptics feedback
    @State private var haptics: Bool = false
    @State private var isExpanded: Bool = false
    /// For Zoom transtiion
    @Namespace private var namespace
    var body: some View {
        Button {
            if isHapticsEnabled {
                haptics.toggle()
            }
            isExpanded.toggle()
        } label: {
            label
                .matchedTransitionSource(id: "MENUCONTENT", in: namespace)
        }
        /// Applying Menu Style
        .applyStyle(style)
        .popover(isPresented: $isExpanded) {
            PopOverHelper {
                content
            }
            .navigationTransition(.zoom(sourceID: "MENUCONTENT", in: namespace))
        }
        .sensoryFeedback(.selection, trigger: haptics)
    }
}

private struct PopOverHelper<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var isVisible: Bool = false

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    isVisible = true
                }
            }
            .presentationCompactAdaptation(.popover)
    }
}

/// Custom Date Filter view
@available(iOS 26.0, *)
struct DateFilterDemoView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Filter Date Range")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)

            DatePicker("Start Date", selection: .constant(.now), displayedComponents: [.date])
                .datePickerStyle(.compact)
                .font(.caption)

            DatePicker("End Date", selection: .constant(.now), displayedComponents: [.date])
                .datePickerStyle(.compact)
                .font(.caption)

            VStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("Apply")
                        .font(.callout)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                }
                .tint(.blue)
                .buttonStyle(.glassProminent)

                Text("Maximum Range is 1 Year.")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 15)
        }
        .padding(15)
        .frame(width: 250, height: 250)
        .interactiveDismissDisabled()
    }
}

enum CustomMenuStyleiOS26: String, CaseIterable {
    case glass = "Glass"
    case glassProminent = "GlassProminent"
}

@available(iOS 26.0, *)
private extension View {
    @ViewBuilder
    func applyStyle(_ style: CustomMenuStyleiOS26) -> some View {
        switch style {
        case .glass:
            buttonStyle(.glass)
        case .glassProminent:
            buttonStyle(.glassProminent)
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    PopMenuiOS26DatePickerDemo()
}
