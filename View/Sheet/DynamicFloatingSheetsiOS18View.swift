//
//  DynamicFloatingSheetsiOS18View.swift
//  animation

import SwiftUI

enum CurrentView {
    case actions
    case period
    case keypad
}

struct DynamicFloatingSheetsiOS18ViewDemo: View {
    /// View Properties
    @State private var show: Bool = false
    @State private var currentView: CurrentView = .actions
    @State private var selectedPeriod: Period?
    @State private var selectedKeypadAction: KeyPadAction?
    @State private var duration: String = ""

    var body: some View {
        Button("Show Style1") {
            show.toggle()
        }
        .systemTrayView($show) {
            VStack(spacing: 20) {
                ZStack {
                    switch currentView {
                        case .actions: View1()
                                .transition(.blurReplace)

                        case .period: View2()
                                .transition(.blurReplace)

                        case .keypad:View3()
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
    }

    @ViewBuilder
    func View1() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose Subscription")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    /// dismiss sheet
                    show = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 10)

            ForEach(keypadActions, id:\.self) { action in
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
    @ViewBuilder
    func View2() -> some View {
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
    @ViewBuilder
    func View3() -> some View {
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
