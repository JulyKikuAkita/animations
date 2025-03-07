//
//  AppIntentView.swift
//  animation
import SwiftUI
import SwiftData
import AppIntents

//@main
struct demoIntentApp: App {
    var body: some Scene {
        WindowGroup {
            AppIntentDemoView()
                /// defined in AppIntentView for App shortcut demo
                .modelContainer(for: Memory.self)
        }
    }
}

@Model
class Memory {
    var caption: String
    var date: Date
    @Attribute(.externalStorage)
    var imageData: Data

    init(caption: String, date: Date = .now, imageData: Data) {
        self.caption = caption
        self.date = date
        self.imageData = imageData
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)!
    }
}

struct AppIntentDemoView: View {
    @Query(sort: [.init(\Memory.date, order: .reverse)], animation: .smooth)
    var memories: [Memory]
    var body: some View {
        NavigationStack {
            List {
                ForEach(memories) { memory in
                    Section(memory.caption) {
                        if let uitImage = memory.uiImage {
                            Image(uiImage: uitImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Memories")
            .overlay {
                if memories.isEmpty {
                    VStack {
                        Text("No memories yet")
                            .font(.headline)
                        Text("Tap the plus (+) button to add your first memory.")
                            .foregroundColor(.secondary)
                    }
                    .padding(15)
                }
            }
        }
    }
}

#Preview {
    AppIntentDemoView()
}


struct addMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add New Memory"

    /// Getting image from User
    @Parameter(
        title: .init(stringLiteral: "Choose an Image"),
        description: "Memory to be added",
        /// any image type
        supportedContentTypes: [.image],
        /// e.g., if we get an image from the photos app, the photo can be passed to the intent (connection)
        inputConnectionBehavior: .connectToPreviousIntentResult
    ) var imageFile: IntentFile

    @Parameter(title: "Caption") var caption: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Memory.self)
        let context = ModelContext(container)

        let imageData = try await imageFile.data(contentType: .image)
        let memory = Memory(caption: caption, imageData: imageData)

        context.insert(memory)
        try context.save()

        return .result(dialog: "Memory added successfully!")
    }
}


struct AddMemoryShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: addMemoryIntent(),
            phrases: [
                "create a new \(.applicationName) memory"
            ],
            shortTitle: "Create Memory",
            systemImageName: "memories"
        )
    }
}
