//
//  NumberPadTextEffectsView.swift
//  animation

import SwiftUI

struct KeypadValue {
    var stringValue: String = ""
    var stackViews: [Number] = []

    struct Number: Identifiable {
        var id: String = UUID().uuidString
        var value: String = ""
        var isComma: Bool = false
        /// id for matched gemonetry effect
        var commaID: Int = 0
    }

    mutating func append(_ number: Int) {
        /// do not start with number 0 first or not exceed max number length
        guard !isExceedMaxLength, number == 0 ? !stringValue.isEmpty : true else { return }
        stringValue.append(String(number))
        stackViews.append(.init(value: String(number)))
        updateCommas()
    }

    mutating func removeLast() {
        guard !stringValue.isEmpty else { return }
        stringValue.removeLast()
        stackViews.removeLast()
        updateCommas()
    }

    mutating func updateCommas() {
        guard let number = Int(stringValue) else { return }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: localFormat)

        if let formattedNumber = formatter.string(from: .init(value: number)) {
            /// remove existing commas
            stackViews.removeAll(where: \.isComma)

            let stackWithCommas = formattedNumber.compactMap {
                let value = String($0)
                return Number(value: value, isComma: value == ",")
            }

            /// We only want to update commas without impacting existing number stack views
            /// in order to preserve the animation id to achive a text push effect instead of replace effect
            /// aka animating slide the comma to the updated postiion
            /// (trying to re init the stackViews instead of replace comma to see the difference)
            let onlyCommaArray = stackWithCommas.filter(\.isComma)
            for index in stackWithCommas.indices {
                let placeHolder = stackWithCommas[index]
                let commaIndex = onlyCommaArray.firstIndex(where: { $0.id == placeHolder.id }) ?? 0
                if placeHolder.isComma {
                    stackViews.insert(.init(value: ",", isComma: true, commaID: commaIndex), at: index)
                }
            }
        }
    }

    var isEmpty: Bool {
        stringValue.isEmpty
    }

    var isExceedMaxLength: Bool {
        stringValue.count >= 11
    }

    var intValue: Int {
        Int(stringValue) ?? 0
    }

    var localFormat: String {
        "en_US"
    }
}

struct NumberPadTextEffectsViewDemoView: View {
    /// View Properties
    @State private var value: KeypadValue = .init()
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 20) {
            Text("Send Money")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)

            VStack(spacing: 6) {
                Image(.fox)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(.circle)

                Text("Fox")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 2) {
                AnimatedNumberTextView()
            }
            .frame(height: 50)
            .padding(.bottom, 30)

            CustomNumberKeypad()
        }
        .fontDesign(.rounded)
        .padding(15)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    func AnimatedNumberTextView() -> some View {
        HStack(spacing: 2) {
            Text("$")

            Text(value.isEmpty ? "0" : "")
                .frame(width: value.isEmpty ? nil : 0)
                .contentTransition(.numericText())
                .padding(.leading, 3)

            ForEach(value.stackViews) { number in
                Group {
                    if number.isComma {
                        Text(",")
                            .contentTransition(.interpolate)
                            .matchedGeometryEffect(id: number.commaID, in: animation)
                    } else {
                        Text(number.value)
                            .contentTransition(.interpolate)
                            .transition(.asymmetric(insertion: .push(from: .bottom),
                                                    removal: .push(from: .top)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    func CustomNumberKeypad() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
            ForEach(1 ... 9, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        value.append(index)
                    }
                } label: {
                    Text("\(index)")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .contentShape(.rect)
                }
            }

            Spacer()

            ForEach(["0", "delete.backward.fill"], id: \.self) { string in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if string == "0" {
                            value.append(0)
                        } else {
                            value.removeLast()
                        }
                    }
                } label: {
                    Group {
                        if string == "0" {
                            Text("0")
                        } else {
                            Image(systemName: string)
                        }
                    }
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .contentShape(.rect)
                }
                /// long pressed back button to remove input
                .buttonRepeatBehavior(string == "0" ? .disabled : .enabled)
            }
        }
        .buttonStyle(KeypadButtonStyle())
        .foregroundStyle(.white)
    }
}

#Preview {
    NumberPadTextEffectsViewDemoView()
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray.opacity(0.2))
                    .opacity(configuration.isPressed ? 1 : 0)
                    .padding(.horizontal, 5)
            }
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
    }
}
