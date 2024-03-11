//
//  ToggleStateIntent.swift
//  animation

import SwiftUI
import AppIntents

/// iOS 17: app intent improvement:
///  we can simply define an aciton for our widget button through the app intents
struct ToggleStateIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task STate"
    
    /// Parameters
    /// these parameters can be passed with the button call from widgets
    ///  only accept primary type such as int, string but not UUID()
    @Parameter(title: "Task ID")
    var id: String
    init() {
        
    }
    
    init(id: String) {
        self.id = id
    }
    
    func perform() async throws -> some IntentResult {
        /// Sync data with db or network call
        if let index = TaskDataModel.shared.tasks.firstIndex(where: {
            $0.id == id
        }) {
            TaskDataModel.shared.tasks[index].isCompleted.toggle()
        }
        return .result()
    }
    
}
