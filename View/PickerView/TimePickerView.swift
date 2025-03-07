//
//  TimePickerView.swift
//  animation

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
            CustomView("hours", 0...24, $hours)
            CustomView("mins", 0...60, $minutes)
            CustomView("seconds", 0...60, $seconds)
        }
        .offset(x: -25)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .frame(height: 35)
        }
    }

    @ViewBuilder
    private func CustomView(_ title: String, _ range: ClosedRange<Int>, _ selection: Binding<Int>) -> some View {
        PickerViewWithoutIndicator(selection: selection) {
            ForEach(range, id:\.self) { value in
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

fileprivate struct RemovePickerIndicator: UIViewRepresentable {
    var result: () -> ()
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let pickerView = view.pickerView {
                if pickerView.subviews.count >= 2 { // trial and error and found 2nd subview contained the bg for the UIPicker view
                    pickerView.subviews[1].backgroundColor = .clear
                }
                result()
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

fileprivate extension UIView {
    var pickerView: UIPickerView? {
        if let view = superview as? UIPickerView {
            return view
        }

        return superview?.pickerView
    }
}
