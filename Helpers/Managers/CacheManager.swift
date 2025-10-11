//
//  CacheManager.swift
//  animation
//
//  Choices of cache manager:
//  1. NSCache API
//  2. SwiftData or CoreData
//  3. Store files in the Cache directory using FileManager
//

import SwiftData
import SwiftUI

struct CacheManagerTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Cache.self)
        }
    }
}

final class CacheManager {
    @MainActor static let shared = CacheManager()
    /// Separate Context for Cache Operations
    let context: ModelContext? = {
        guard let container = try? ModelContainer(for: Cache.self) else { return nil }
        let context = ModelContext(container)
        return context
    }()

    /// demo purpose, usually 20-30 or based on scenarios
    let cacheLimit = 2

    init() {
        removeExpiredItems()
    }

    private func removeExpiredItems() {
        guard let context else { return }

        let today: Date = .now
        let predicate = #Predicate<Cache> { today > $0.expiration }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            try context.enumerate(descriptor) {
                // print("Expired item id: \($0.cacheID)")
                context.delete($0)
            }
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func verifyLimits() throws {
        guard let context else { return }
        let countDescriptor = FetchDescriptor<Cache>()
        let count = try context.fetchCount(countDescriptor)

        if count >= cacheLimit {
            /// always start removing with the oldest item
            var fetchDescriptor = FetchDescriptor<Cache>(sortBy: [.init(\.creation, order: .forward)])
            fetchDescriptor.fetchLimit = 1

            if let oldCache = try context.fetch(fetchDescriptor).first {
                context.delete(oldCache)
            }
        }
    }

    /// CRUD operation
    func insert(id: String, data: Data, expirationDays: Int) throws {
        guard let context else { return }
        /// updating existing cache
        if let cache = try get(id: id) {
            context.delete(cache) /// or update cache
        }

        try verifyLimits()

        let expiration = calculateExpirationDate(expirationDays)
        let cache = Cache(cacheID: id, data: data, expiration: expiration)
        context.insert(cache)
        try context.save()
    }

    func get(id: String) throws -> Cache? {
        guard let context else { return nil }
        let predicate = #Predicate<Cache> { $0.cacheID == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        /// for demo, only one
        descriptor.fetchLimit = 1

        if let cache = try context.fetch(descriptor).first {
            return cache
        }
        return nil
    }

    func remove(id: String) throws {
        guard let context else { return }
        if let cache = try get(id: id) {
            context.delete(cache)
            try context.save()
        }
    }

    func removeAll() throws {
        guard let context else { return }
        /// Empty Descriptor returns all objects
        let descriptor = FetchDescriptor<Cache>()
        try context.enumerate(descriptor) {
            context.delete($0)
        }
        try context.save()
    }

    private func calculateExpirationDate(_ days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: days, to: .now) ?? .now
    }
}

@Model
class Cache {
    var cacheID: String
    var data: Data
    var expiration: Date
    var creation: Date = Date()

    init(cacheID: String, data: Data, expiration: Date) {
        self.cacheID = cacheID
        self.data = data
        self.expiration = expiration
    }
}
