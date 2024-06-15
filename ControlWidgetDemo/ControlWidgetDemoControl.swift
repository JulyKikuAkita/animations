//
//  ControlWidgetDemoControl.swift
//  ControlWidgetDemo
//
//  Created by IFang Lee on 6/15/24.
//

import AppIntents
import SwiftUI
import WidgetKit

struct ControlWidgetDemoControl: ControlWidget {
    static let kind: String = "nanachi.animation.ControlWidgetDemo"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
//            ControlWidgetToggle(
//                isOn: SharedManager.shared.isTurnedOn, action: ControlWidgetDemoToggleIntent() ) { isTurnedOn in
//                    Image(systemName: isTurnedOn ? "dog.fill" : "dog")
//                    Text(isTurnedOn ? "Show up" : "Hidden")
//                } label: {
//                    Text("Dog patch")
//                }
            
            ControlWidgetButton(action: CaffeinUpdateIntent(amount: 3.3)) {
                Image(systemName:"cup.and.saucer.fill")
                Text("Caffeine In Take")
                let amount = SharedManager.shared.caffeineInTake
                Text("\(String(format: "%.1f", amount)) msg")
            }
        }
        // below default template
//        StaticControlConfiguration(
//            kind: Self.kind,
//            provider: Provider()
//        ) { value in
//            ControlWidgetToggle(
//                "Start Timer",
//                isOn: value,
//                action: StartTimerIntent(),
//                valueLabel: { isRunning in
//                    Label(isRunning ? "On" : "Off", systemImage: "timer")
//                }
//            )
//        }
//        .displayName("Timer")
//        .description("A an example control that runs a timer.")
    }
}

struct CaffeinUpdateIntent: AppIntent {
    static var title: LocalizedStringResource { "Update Caffeine In Take" }
    
    init(){}
    
    init(amount: Double) {
        self.amount = amount
    }
    
    @Parameter(title: "Amount Taken")
    var amount: Double
    
    func perform() async throws -> some IntentResult {
        /// Update contents here
        SharedManager.shared.caffeineInTake += amount
        
        return .result()
    }
}

struct ControlWidgetDemoToggleIntent: SetValueIntent {
    static var title: LocalizedStringResource { "Find doge in the dog patch" }
    
    @Parameter(title: "Locating...")
    var value: Bool
    
    func perform() async throws -> some IntentResult {
        /// Update contents here
        SharedManager.shared.isTurnedOn = value
        return .result()
    }
}

extension ControlWidgetDemoControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool {
            false //set to true to show timer in control widget
        }

        func currentValue() async throws -> Bool {
            let isRunning = true // Check if the timer is running
            return isRunning
        }
    }
}

struct StartTimerIntent: SetValueIntent {
    static var title: LocalizedStringResource { "Start a timer" }

    @Parameter(title: "Timer is running")
    var value: Bool

    func perform() async throws -> some IntentResult {
        // Start / stop the timer based on `value`.
        return .result()
    }
}
