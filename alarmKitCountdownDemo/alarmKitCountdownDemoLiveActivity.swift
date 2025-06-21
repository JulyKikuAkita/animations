//
//  alarmKitCountdownDemoLiveActivity.swift
//  alarmKitCountdownDemo
//
//  Created on 6/18/25.

import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct AlarmKitCountdownDemoLiveActivity: Widget {
    @State private var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<CountDownAttributes>.self) { context in
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    switch context.state.mode {
                    case let .countdown(countdown):
                        Group {
                            Text(context.attributes.presentation.countdown?.title ?? "")
                                .font(.title3)

                            Text(countdown.fireDate, style: .timer)
                        }
                    case let .paused(paused):
                        Group {
                            Text(context.attributes.presentation.paused?.title ?? "")
                                .font(.title3)

                            Text(formatter.string(
                                from: paused.totalCountdownDuration - paused.previouslyElapsedDuration)
                                ?? "0:00"
                            )
                            .font(.title2)
                        }
                    case .alert:
                        Group {
                            Text(context.attributes.presentation.alert.title)
                                .font(.title3)

                            Text("0:00")
                                .font(.title2)
                        }
                    @unknown default:
                        fatalError()
                    }
                }
                .lineLimit(1)

                Spacer(minLength: 0)

                let alarmId = context.state.alarmID

                Group {
                    if case .paused = context.state.mode {
                        Button(intent: AlarmActionIntent(
                            id: alarmId,
                            isCancel: false,
                            isResume: true
                        )) {
                            Image(systemName: "play.fill")
                        }
                        .tint(.orange)
                    } else {
                        Button(intent: AlarmActionIntent(
                            id: alarmId,
                            isCancel: false
                        )) {
                            Image(systemName: "pause.fill")
                        }
                        .tint(.orange)
                    }

                    Button(intent: AlarmActionIntent(id: alarmId, isCancel: true)) {
                        Image(systemName: "xmark")
                    }
                    .tint(.red)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .font(.title)
            }
            .padding(15)
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("Minimal Content")
            }
            .keylineTint(Color.red)
        }
    }
}
