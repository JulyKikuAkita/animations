//
//  PopMenuiOS26+DatePickerDemo.swift
//  animation
//
//  Created on 9/24/25.
// iOS 26 only: popover API and Zoom transition on sheet/popovers
// animation note:
// apply matchedTransitionSource modifier before glass effect to avoid clip the glass + shadows
// also glass background is auto applied for the transition without workaround
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
