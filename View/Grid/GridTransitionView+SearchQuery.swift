//
//  GridTransitionView+SearchQuery.swift
//  animation
//
//  ⚠️  HELPER FILE — `SearchQueryView` is consumed only by
//      [[GridTransitionView]] (same folder). Don't use this file
//      standalone; it has no demo entry point.
//
//  Learning point
//  ──────────────
//  Tiny generic wrapper that turns a `String` search term into a
//  reactive SwiftData fetch. Drops it inline as
//  `SearchQueryView(searchText: ...) { notes in ... }` and the
//  trailing closure gets the filtered `[Note]` array, auto-
//  refreshing on edits.
//
//  Why a separate type for what looks like one line of `@Query`?
//  ─────────────────────────────────────────────────────────────
//  Because `@Query`'s filter is FIXED at view-init time — you can't
//  rebuild the predicate in response to a `searchText` `@State`
//  change inside the SAME view. Wrapping the query in this child
//  view lets the parent re-instantiate `SearchQueryView` whenever
//  `searchText` changes, which DOES rebuild the predicate. Standard
//  workaround for SwiftData's filter-immutability.
//
//  The predicate uses `localizedStandardContains` so the search is
//  case- and diacritic-insensitive (matches "café" with "cafe").
//
//  Key APIs
//  ────────
//  • `@Query(filter:sort:animation:)` — SwiftData's reactive fetch.
//  • `#Predicate<Note> { ... }` — Swift macro that compiles to a
//    `Predicate<Note>` usable by SwiftData and CloudKit.
//  • `.localizedStandardContains(_:)` — Foundation; the right
//    case-insensitive contains for user-facing search.
//  • The `isSearchTextEmpty || ...` short-circuit — SwiftData's
//    `#Predicate` doesn't always handle empty-string filters
//    correctly, so we explicitly bypass when the search is empty.
//
//  How to apply
//  ────────────
//  Copy this pattern verbatim whenever a `@Query` needs a runtime
//  filter parameter. Generic on `Content: View` so it can wrap
//  any rendering of the result list.
//
//  See also
//  ────────
//  • GridTransitionView.swift — the consumer.
//
import SwiftData
import SwiftUI

struct SearchQueryView<Content: View>: View {
    init(searchText: String, @ViewBuilder content: @escaping ([Note]) -> Content) {
        self.content = content
        let isSearchTextEmpty = searchText.isEmpty

        let predicate = #Predicate<Note> {
            isSearchTextEmpty || $0.title.localizedStandardContains(searchText)
        }

        _notes = .init(
            filter: predicate,
            sort: [.init(\.dateCreated, order: .reverse)],
            animation: .snappy
        )
    }

    var content: ([Note]) -> Content
    @Query var notes: [Note]
    var body: some View {
        content(notes)
    }
}
