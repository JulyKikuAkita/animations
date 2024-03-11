//
//  TaskWidget.swift
//  TaskWidget
//
//  How to test the widgets
//  1. run the main app
//  2. build and run the widget after stopping the main app and waiting till it has fully loaded
//  3. Any update of the widget need to repeat step 1 and 2
//  Note: interactino with the widget when mian app in background mode might not be working
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        /// Customized task view
        TaskEntry(lastThreeTasks: Array(TaskDataModel.shared.tasks.prefix(3)))

    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let entry = TaskEntry(lastThreeTasks: Array(TaskDataModel.shared.tasks.prefix(3)))
        completion(entry)

    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        /// Fetch data here
        let lastThreeTasks = Array(TaskDataModel.shared.tasks.prefix(3))
        let latestEntries = [TaskEntry(lastThreeTasks: lastThreeTasks)]

        let timeline = Timeline(entries: latestEntries, policy: .atEnd)
        completion(timeline)
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date = .now
    /// 3 items suitable for the samll widget view
    var lastThreeTasks: [TaskModel]
}

struct TaskWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0)  {
            Text("Task's")
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 6, content: {
                if entry.lastThreeTasks.isEmpty {
                    Text("No Task Found")
                        .font(.callout)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    /// sorting by completed tasks last
                    ForEach(entry.lastThreeTasks.sorted {
                        !$0.isCompleted && $1.isCompleted
                    }) { task in
                        HStack(spacing: 6) {
                            /// SwiftUI widgets support 2 interaction modes
                            ///  1. Button with inten  2. Toggle
                            ///   rest interactions will be ignored
                            Button(intent: ToggleStateIntent(id: task.id)) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                          
                            
                            VStack(alignment: .leading, spacing: 4, content: {
                                Text(task.taskTitle)
                                    .textScale(.secondary)
                                    .lineLimit(1)
                                    .strikethrough(task.isCompleted, pattern: .solid, color: .primary)
                                
                                Divider()
                            })
                        }
                        
                        if task.id != entry.lastThreeTasks.last?.id {
                            Spacer(minLength: 0)
                        }
                        
                    }
                }
            })
        }
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TaskWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TaskWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Task Widget")
        .description("This is an example of interactive widget.")
    }
}

#Preview(as: .systemSmall) {
    TaskWidget()
} timeline: {
    TaskEntry(lastThreeTasks: Array(TaskDataModel.shared.tasks.prefix(3)))
}
