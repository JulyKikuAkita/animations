//
//  Message.swift
//  animation
import SwiftUI

struct Message: Identifiable {
    var id: UUID = .init()
    var message: String
    var isReply: Bool = false
    var isFit: Bool? = nil
}

let messages: [Message] = [
    .init(message: text1),
    .init(message: text2, isReply: true),
    .init(message: text3),
    .init(message: text4),
    .init(message: text5, isReply: true),
    .init(message: text6),
    .init(message: text7),
    .init(message: text2, isReply: true),
    .init(message: text3),
    .init(message: text4),
    .init(message: text1, isReply: true),
    .init(message: text5),
    .init(message: text4, isReply: true),
    .init(message: text3, isReply: true),
    .init(message: text6),
    .init(message: text7),
]

let text1 = """
Using the workflow_run event in GitHub Actions is a powerful way to chain workflows
and ensure that one set of jobs must complete successfully before another set begins.
"""
let text2 = "This approach is useful for maintaining a clean and robust CI/CD pipeline."
let text3 = "This setup ensures that a sanity check is performed before any automatic cascading merge is attempted."
let text4 = """
If the sanity check fails, the cascading merge will not proceed,
thereby maintaining the stability and integrity of your branches.
"""
let text5 = """
Workflow Name Matching: Ensure that the workflow name in the workflows array
matches exactly the name defined in the first workflow.
"""
let text6 = """
Permissions: Ensure that the repository has the necessary permissions for GitHub Actions
to trigger workflows and perform required actions.
"""
let text7 = """
Correct Event Types: Ensure that the workflow_run event is correctly set
to trigger on completed workflows and the condition conclusion == 'success' is used correctly.
"""
