//
//  TaskModel.swift
//  animation

import SwiftUI
struct TaskModel: Identifiable {
    var id: String = UUID().uuidString
    var taskTitle: String
    var isCompleted: Bool = false
    
    /// Other properties
}

/// Sample data model (replace w/ network calls)
class TaskDataModel {
    static let shared = TaskDataModel()
    
    var tasks: [TaskModel] = [
        .init(taskTitle: "eat"),
        .init(taskTitle: "pray", isCompleted: true),
        .init(taskTitle: "walk dog")
    ]
}
