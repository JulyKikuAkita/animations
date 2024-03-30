//
//  TodoView.swift
//  animation
import SwiftUI
import SwiftData

struct TodoView: View {
    var body: some View {
        NavigationStack {
            Home()
                .navigationTitle("Todo List")
        }
    }
}

public struct Home: View {
    /// active Todo's
    @Query(filter: #Predicate<Todo> { !$0.isCompleted }, sort:
            [SortDescriptor(\Todo.lastUpdated, order: .reverse)], animation: .snappy) private var activeList: [Todo]
    /// Model context
    @Environment(\.modelContext) private var context
    @State private var showAll: Bool = false
    public var body: some View {
        List {
            Section(activeSectionTitle) {
                ForEach(activeList) {
                    TodoRowView(todo: $0)
                }
            }
            
            CompletedTaskListView(showAll: $showAll)
            
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    /// Creating an empty todo task
                    let todo = Todo(task: "", priority: .medium)
                    /// Saving item into context
                    context.insert(todo)
                }, label: {
                    Image(systemName: "plus.circle.fill")
                        .fontWeight(.light)
                        .font(.system(size: 42))
                })
            }
        }
    }
    
    var activeSectionTitle: String {
        let count = activeList.count
        return count == 0 ? "Active" : "Active (\(count))"
    }
}
#Preview {
    ContentView()
}
