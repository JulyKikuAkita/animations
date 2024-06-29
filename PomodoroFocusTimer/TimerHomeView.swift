//
//  TimerHomeView.swift
//  demoApp
// https://pomofocus.io/ -> or Tomato Timer
// https://www.youtube.com/watch?v=FG6nYxhpAEk

import SwiftUI
import SwiftData

struct TimerHomeView: View {
    /// Customization Properties
    @State private var background: Color = .red
    /// View Properties
    @State private var flipClockTime: Time = .init()
    @State private var startTimer: Bool = false
    @Query(
        sort: [SortDescriptor(\Recent.date, order: .reverse)],
        animation: .snappy
    ) private var recents: [Recent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Pomodoro")
                .font(.largeTitle.bold())
                .padding(.top, 15)
            
            /// Flip Clock Text Effect View
            TimerView()
                .padding(.top, 35)
                .offset(y: -15)
            
            /// Custom Time Picker
            TimePickerView(
                style: .init(.gray.opacity(0.15)),
                hours: $flipClockTime.hours,
                minutes: $flipClockTime.minutes,
                seconds: $flipClockTime.seconds
            )
            .padding(15)
            .environment(\.colorScheme, .light)
            .background(.white, in: .rect(cornerRadius: 10))
            
            TimerButton()
            
            RecentsView()
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(background.gradient)
    }
    
    /// Start/Stop Timer button
    @ViewBuilder
    func TimerButton() -> some View {
        Button {
            startTimer.toggle()
            
            if startTimer {
                startTheTimer()
            } else {
                stopTheTimer()
            }
        } label: {
            Text(!startTimer ? "Start Timer" : "Stop Timer")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.white, in: .rect(cornerRadius: 10))
                .contentShape(.rect(cornerRadius: 10))
        }
        .disableWithOpacity(flipClockTime.isZero)
    }
    
    /// Timer actions
    func startTheTimer() {
        // TODO:
        // https://www.youtube.com/watch?v=FG6nYxhpAEk 12:30
    }
    
    func stopTheTimer() {
        
    }
    
    /// Most recent timer
    @ViewBuilder
    func RecentsView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recents")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .opacity(recents.isEmpty ? 0 : 1)
            
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(recents) { value in
                        let isHour = value.hours > 0
                        let isSeconds = value.minutes == 0 && value.hours == 0 && value.seconds != 0
                        
                        HStack(spacing: 0) {
                            Text(isHour ? "\(value.hours)" : isSeconds ? "\(value.seconds)" : "\(value.minutes)")
                            Text(isHour ? "h" : isSeconds ? "s" : "m")
                        }
                        .font(.callout)
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 50)
                        .background(.white, in: .circle)
                        /// Context Menu Shape
                        .contentShape(.contextMenuPreview, .circle)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                /// Deleting this item from the Swift Data
                            }
                        }
                        .onTapGesture {
                            withAnimation(.linear) {
                                ///  init as current timer settings
                                flipClockTime = .init(
                                    hours: value.hours,
                                    minutes: value.minutes,
                                    seconds: value.seconds
                                )
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 10)
    }
    
    @ViewBuilder
    func TimerView() -> some View {
        let size: CGSize = .init(width: 100, height: 120)
        HStack(spacing: 0) {
            TimerViewHelper(title: "Hours", value: $flipClockTime.hours, size: size)
            TimerViewHelper(title: "Minutes", value: $flipClockTime.minutes, size: size)
            TimerViewHelper(title: "Seconds", value: $flipClockTime.seconds, size: size, isLast: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func TimerViewHelper(title: String, value: Binding<Int>, size: CGSize, isLast: Bool = false) -> some View {
        Group {
            VStack(spacing: 10) {
                FlipClockTextEffectView(
                    value: value,
                    size: size,
                    fontSize: 60,
                    cornerRadius: 18,
                    foreground: .black,
                    background: .white
                )
                
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize() // auto lint limit 1
            }
            
            if !isLast {
                VStack(spacing: 15) {
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    TimerHomeView()
}

/// Custom View Extension
extension View {
    /// Disable view with opacity
    @ViewBuilder
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.3), value: condition)
    }
}
