//
//  AppIntent.swift
//  GraphWidget
//
//  Created by IFang Lee on 3/31/24.
//

import WidgetKit
import AppIntents
import SwiftUI

/// Tab Button Intent
struct TabButtonIntent: AppIntent {
    static var title: LocalizedStringResource = "Tab Button Intent"
    @Parameter(title: "App ID", default: "")
    var appID: String
    
    init() {}
    
    init(appID: String) {
        self.appID = appID
    }
    
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.setValue(appID, forKey: "selectedApp")
        return .result()
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    // An example configurable parameter.
    @Parameter(title: "Line Chart", default: false)
    var isLineChart: Bool
    
    /// List of colors for chart tint
    @Parameter(title: "Chart Tint", query: ChartTintQuery())
    var chartTint: ChartTint?
}

struct ChartTint: AppEntity {
    /// Used later for querying
    var id: UUID = .init()
    /// Color title
    var name: String
    /// Color value
    var color: Color
    
    static var defaultQuery = ChartTintQuery()
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Chart Tint"
    var displayRepresentation: DisplayRepresentation {
        return .init(title: "\(name)")
    }
}

struct ChartTintQuery: EntityQuery {
    func entities(for identifiers: [ChartTint.ID]) async throws -> [ChartTint] {
        /// Filtering using id
        return chartTints.filter { tint in
            identifiers.contains(where: { $0 == tint.id })
        }
    }
    
    func suggestedEntities() async throws -> [ChartTint] {
        return chartTints
    }
    
    func defaultResult() async -> ChartTint? {
        return chartTints.first
    }
}

var chartTints: [ChartTint] = [
    .init(name: "Red", color: .red),
    .init(name: "Green", color: .green),
    .init(name: "Yellow", color: .yellow),
    .init(name: "Purple", color: .purple),
    .init(name: "Pink", color: .pink),
    .init(name: "Cyan", color: .cyan),
]
