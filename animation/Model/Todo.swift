//
//  Todo.swift
//  animation

import SwiftUI
import SwiftData

@Model
class Todo {
    private(set) var taskID: String = UUID().uuidString
    var task: String
    var isCompleted: Bool = false
    var priority: Priority = Priority.medium // normal
    var lastUpdated: Date = Date.now
    
    init(task: String, priority: Priority) {
        self.task = task
//        self.isCompleted = isCompleted
        self.priority = priority
    }
    
}

/// Priority status
enum Priority: String, Codable, CaseIterable {
    case high = "High"
    case medium = "Normal"
    case low = "Low"
    
    /// Priority color
    var color: Color {
        switch self {
        case .high:
            return .red
        case .medium:
              return .green
        case .low:
            return .cyan
        }
    }
}
