//
//  DynamicFloatingSheetsiOS18View.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — `.blurReplace` transition + `.contentTransition(.numericText())`
//  are the gating APIs.
//
//  Learning point
//  ──────────────
//  Multi-step floating sheet that swaps between sub-views in place
//  (subscription options → period picker → custom keypad) instead
//  of pushing a navigation stack. Each transition uses
//  `.blurReplace` so the swap feels like one continuous sheet
//  morphing through three layouts rather than three separate
//  screens.
//
//  Why `.blurReplace` and not a navigation push?
//  ─────────────────────────────────────────────
//  The sheet detent stays the same across steps. A navigation push
//  would slide content sideways — reads as "deeper into unrelated
//  detail." Blur-replace reads as "this same UI is now in a
//  different mode" — right semantic for picker / config flows.
//
//  Key APIs
//  ────────
//  • `.transition(.blurReplace)` — iOS 17+. The swap effect.
//  • `.contentTransition(.numericText())` — animates digit changes
//    (price, duration) without a hard cut.
//  • `.contentTransition(.symbolEffect)` — animates SF Symbol
//    swaps.
//  • `@ViewBuilder` switch over a `CurrentView` enum to drive
//    which sub-view renders.
//
//  How to apply
//  ────────────
//  Use whenever a sheet has 2–3 RELATED steps that should feel
//  like one surface in different modes (subscription → period,
//  filter → operator, search → results). For unrelated multi-step
//  flows, a NavigationStack inside the sheet is clearer.
//
//  See also
//  ────────
//  • DynamicSheetView.swift — older horizontal-paged sheet
//    pattern with custom geometry preferences (iOS 15 baseline).
//  • DynamicHeightSheetViewiOS26.swift — wraps this demo with
//    iOS 26's `onGeometryChange`-driven dynamic height.
//
import SwiftUI

enum CurrentView {
    case actions
    case period
    case keypad
}

struct DynamicFloatingSheetsiOS18ViewDemo: View {
    @State private var show: Bool = false
    var body: some View {
        Button("Show Style1") {
            show.toggle()
        }
        .systemTrayView($show) {
            DynamicFloatingSheetsiOS18View()
        }
    }
}

struct DynamicFloatingSheetsiOS18View: View {
    /// View Properties
    @State private var currentView: CurrentView = .actions
    @State private var selectedPeriod: Period?
    @State private var selectedKeypadAction: KeyPadAction?
    @State private var duration: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                switch currentView {
                case .actions: view1()
                    .transition(.blurReplace)

                case .period: view2()
                    .transition(.blurReplace)

                case .keypad: view3()
                    .transition(.blurReplace)
                }
            }
            .compositingGroup()

            Button {
                withAnimation(.bouncy) {
                    currentView = .period
                }
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(Color.blue, in: .capsule)
            }
            .padding(.top, 15)
        }
        .padding(20)
    }

    func view1() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose Subscription")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    /// dismiss sheet
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 10)

            ForEach(keypadActions, id: \.self) { action in
                let isSelected: Bool = selectedKeypadAction?.id ?? "" == action.id

                HStack(spacing: 10) {
                    Image(systemName: action.image)
                        .font(.title)
                        .frame(width: 40)

                    Text(action.title)
                        .fontWeight(.semibold)

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                        .font(.title)
                        .contentTransition(.symbolEffect)
                        .foregroundStyle(isSelected ? Color.blue : Color.gray.opacity(0.2))
                }
                .padding(.vertical, 6)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedKeypadAction = isSelected ? nil : action
                    }
                }
            }
        }
    }

    /// Grid Box view
    // swiftlint:disable:next function_body_length
    func view2() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose Period")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.bouncy) {
                        currentView = .actions
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 25)

            Text("Choose the period to get subscribed.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .padding(.bottom, 20)

            /// Grid Box view
            LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 15) {
                ForEach(periods) { period in
                    let isSelected: Bool = selectedPeriod?.id ?? "" == period.id

                    VStack(spacing: 6) {
                        Text(period.title)
                            .font(period.value == 0 ? .title3 : .title2)
                            .fontWeight(.semibold)

                        if period.value != 0 {
                            Text(period.value == 1 ? "Month" : "Months")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill((isSelected ? Color.blue : Color.gray).opacity(isSelected ? 0.2 : 0.1))
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            if period.value == 0 {
                                /// Go to KeyPad View
                                currentView = .keypad
                            } else {
                                selectedPeriod = isSelected ? nil : period
                            }
                        }
                    }
                }
            }
        }
    }

    /// Custom Keypad value view
    // swiftlint:disable:next function_body_length
    func view3() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose Duration")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.bouncy) {
                        currentView = .period
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 25)

            VStack(spacing: 6) {
                Text(duration.isEmpty ? "0" : duration)
                    .font(.system(size: 60, weight: .black))
                    .contentTransition(.numericText())

                Text("Days.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, 20)

            LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 15) {
                ForEach(keypadValues) { keyValue in
                    Group {
                        if keyValue.isBack {
                            Image(systemName: keyValue.title)
                        } else {
                            Text(keyValue.title)
                        }
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            if keyValue.isBack {
                                if !duration.isEmpty {
                                    duration.removeLast()
                                }
                            } else {
                                duration.append(keyValue.title)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, -15)
        }
    }
}

#Preview {
    DynamicFloatingSheetsiOS18ViewDemo()
}
