//
//  GraphWidget.swift
//  GraphWidget
//
//  Created by IFang Lee on 3/31/24.
//

import WidgetKit
import SwiftUI
import Charts

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), apps: apps)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, apps: apps)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        let entry = SimpleEntry(date: .now, configuration: configuration, apps: apps)
        entries.append(entry)
        
        // no need for timeline as we are passing in fixed demo data
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {  // no need for timeline as we are passing in fixed demo data
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration, apps: apps)
//            entries.append(entry)
//        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let apps: [AppModel]
}

struct GraphWidgetEntryView : View {
    var entry: Provider.Entry
    /// View properties
    // use app storage(user default) to pass data between intent and the widget
    @AppStorage("selectedApp") private var selectedApp: String = "App 1"
    var body: some View {
        VStack(spacing: 15) {
            Text("App Downloads")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Text("Last 7 days")
                .font(.caption2)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            
            let chartTint: Color = entry.configuration.chartTint?.color ?? .cyan
            /// Segmented control with button intent (ios 17)
            HStack(spacing: 0) {
                ForEach(entry.apps) { app in
                    Button(intent: TabButtonIntent(appID: app.id)) { // when button is tapped, we read app id from user default
                        Text(app.id)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(app.id == selectedApp ? .white : .primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background { //manually move the active tabs indicator as geometry effect won't work with widget when the view refreshed with new data
                GeometryReader {
                    let size = $0.size
                    let width = size.width / CGFloat(entry.apps.count)
                    
                    Capsule()
                        .fill(chartTint.gradient)
                        .frame(width: width)
                        .offset(x: width * CGFloat(selectedIndex))
                }
                
            }
            .frame(height: 28)
            .background(.primary.opacity(0.15), in: .capsule)
            
            Chart(selectedAppDownloads) { download in
                if entry.configuration.isLineChart {
                    LineMark(
                        x: .value("Day", dayString(download.date)),
                        y: .value("Downloads", download.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(chartTint)
                    
                    AreaMark(
                        x: .value("Day", dayString(download.date)),
                        y: .value("Downloads", download.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.linearGradient(colors: [
                        chartTint,
                        chartTint.opacity(0.5),
                        .clear
                    ], startPoint: .top, endPoint: .bottom))
                } else {
                    BarMark(
                        x: .value("Day", dayString(download.date)),
                        y: .value("Downloads", download.value)
                    )
                    .foregroundStyle(chartTint.gradient)
                }
            }
        }
    }
    
    func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var selectedAppDownloads: [Downloads] {
        return entry.apps.first(where: { $0.id == selectedApp })?.appDownloads ?? []
    }
    
    var selectedIndex: Int {
        return entry.apps.firstIndex(where: { $0.id == selectedApp }) ?? 0
    }
}

struct GraphWidget: Widget {
    let kind: String = "GraphWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GraphWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemLarge, .systemExtraLarge, .systemMedium])
    }
}

#Preview(as: .systemLarge) {
    GraphWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .init(), apps: apps)
}
