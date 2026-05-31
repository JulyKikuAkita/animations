//
//  GridTransitionView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — `onGeometryChange` is the gating API; SwiftData
//  (`@Query`, `@Model`) requires iOS 17+.
//
//  Companion file: `GridTransitionView+SearchQuery.swift` defines
//  `SearchQueryView` used by this view's `.searchable` integration.
//
//  TODO: Cleanup candidates
//        1. `struct ColorNotes: App { ... }` directly below this
//           header is dead code — it has no `@main` attribute, so
//           it never runs. Same leftover-target pattern as
//           `View/PhotosView/AsyncImageViewerView+SkeletonviewDemo.swift`
//           and `View/Notifications/CustomNotificationsView.swift`.
//           Either re-enable as `@main` or delete.
//        2. The safe-area read via `UIApplication.shared.connectedScenes`
//           (around line ~352) is the pre-iOS-17 idiom; iOS 17+
//           has `safeAreaInsets` reachable via `GeometryReader` /
//           `onGeometryChange`. Modernise when convenient.
//
//  Learning point
//  ──────────────
//  Apple-Notes-style note grid with shared-element transition: tap
//  a card → it expands in place to a fullscreen detail editor;
//  pinch-or-tap to dismiss → it morphs back. SwiftData drives the
//  underlying data (`Note` model), and `matchedGeometryEffect`
//  drives the morph. The full demo bundles five behaviours worth
//  reading separately:
//
//    1. SwiftData CRUD via `@Query` + `@Environment(\.modelContext)`
//       — create/edit/delete notes that persist across launches.
//    2. Shared-element transition between grid card and detail
//       editor via `matchedGeometryEffect(id: note.id, in:
//       animation)`.
//    3. Inline edit-in-place: `TextField` for title and `TextEditor`
//       for body sit ON TOP OF the morphed card; no second view to
//       navigate to.
//    4. Color tagging: each note has a swatch; the grid card and
//       the detail header tint to match.
//    5. Search: `.searchable` filters via `SearchQueryView` (defined
//       in the companion file) which uses a SwiftData `#Predicate`.
//
//  Animation timing trick
//  ──────────────────────
//  The detail view fades its body content in via a delayed
//  `.opacity` so the body doesn't appear until the morph has
//  visually arrived. Without the delay, the body would pop on
//  immediately and undermine the "card is becoming the detail
//  editor" illusion.
//
//  Key APIs
//  ────────
//  • `@Query` + `#Predicate` — SwiftData's reactive fetch; auto-
//    refreshes the grid as notes are inserted/edited/deleted.
//  • `@Environment(\.modelContext)` — write path for inserts and
//    deletes.
//  • `matchedGeometryEffect(id:in:)` — the morph mechanism; ids
//    must be stable (`note.id`) across both source and destination.
//  • `onGeometryChange(for: CGSize.self)` — measures the grid card
//    so the detail view can size itself for the morph.
//  • Project helper `noteAnimation` (View extension) — the unifying
//    animation curve; keeps grid + detail in sync.
//  • `.searchable(text:)` — toolbar search field; routes to the
//    sibling file's `SearchQueryView`.
//
//  How to apply
//  ────────────
//  Use as a starting template for any list-with-detail editor where
//  the items have visual identity (cards with color, image, etc.).
//  Drop SwiftData if you don't need persistence; the morph and
//  search machinery work with plain `@State` arrays too.
//
//  See also
//  ────────
//  • GridTransitionView+SearchQuery.swift — companion; the
//    `SearchQueryView` used here.
//  • View/PhotosView/PhotoGridViewIos26+TransitionEffect.swift —
//    different "grid card → fullscreen" pattern using a manual
//    rect-morph instead of `matchedGeometryEffect`. Compare the
//    two; pick by whether you need pinch-to-dismiss (that file)
//    or simpler tap-to-expand (this file).
//
import SwiftData
import SwiftUI

// TODO: Dead — this `App` struct has no `@main` annotation, so it
//       never runs. Leftover from when this file shipped as its
//       own target. Either annotate `@main` or delete.
struct ColorNotes: App {
    var body: some Scene {
        WindowGroup {
            GridTransitionDemoView()
                .modelContainer(for: Note.self)
        }
    }
}

struct GridTransitionDemoView: View {
    var body: some View {
        GridTransitionView()
    }
}

struct GridTransitionView: View {
    @Namespace private var animation
    /// View Properties
    @State private var searchText: String = ""
    @State private var selectedNote: Note?
    @State private var deleteNote: Note?
    @State private var animateView: Bool = false
    @FocusState private var isKeyboardActive: Bool
    @State private var titleNoteSize: CGSize = .zero

    @Environment(\.modelContext) private var context
    var body: some View {
        SearchQueryView(searchText: searchText) { notes in
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    searchBar()

                    LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                        ForEach(notes) { note in
                            cardView(note)
                                .frame(height: 160)
                                .onTapGesture {
                                    guard selectedNote == nil else { return }
                                    isKeyboardActive = false

                                    selectedNote = note
                                    note.allowsHitTesting = true
                                    withAnimation(noteAnimation) {
                                        animateView = true
                                    }
                                }
                        }
                    }
                }
            }
            .safeAreaPadding(15)
            .overlay {
                GeometryReader { proxy in
                    let size = proxy.size
                    // need forEach to make sure selectNote == nil while transition won't confuse geoMatched animation
                    // (seeing prev card transition is still in progress then
                    // the next selected card transition start and overlapped)
                    ForEach(notes) { note in
                        if note.id == selectedNote?.id, animateView {
                            DetailView(size: size, titleNoteSize: titleNoteSize, animation: animation, note: note)
                                .ignoresSafeArea(.container, edges: .top)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar()
            }
            .focused($isKeyboardActive) // this modifier applies to detailView which has text field too
        }
    }

    @ViewBuilder
    func searchBar() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")

            TextField("Search", text: $searchText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 10))
    }

    /// matchedGeometry effect must be presented only one  in a view
    ///  thus when we show destination view, we must also hide the source view without it's modifying size/position
    @ViewBuilder
    func cardView(_ note: Note) -> some View {
        ZStack {
            /// expanded
            if selectedNote?.id == note.id, animateView {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.clear)
            } else {
                /// minimized
                RoundedRectangle(cornerRadius: 10)
                    .fill(note.color.gradient)
                    .overlay {
                        TitleNoteView(size: titleNoteSize, note: note)
                    }
                    .matchedGeometryEffect(id: note.id, in: animation)
            }
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            titleNoteSize = newValue
        }
    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    func bottomBar() -> some View {
        HStack(spacing: 15) {
            Group {
                if !isKeyboardActive {
                    Button {
                        if selectedNote == nil {
                            createEmptyNote()
                        } else {
                            selectedNote?.allowsHitTesting = false
                            deleteNote = selectedNote
                            withAnimation(
                                /// noteAnimation is spring based thus need some delay
                                noteAnimation.logicallyComplete(after: 0.1),
                                completionCriteria: .logicallyComplete
                            ) {
                                selectedNote = nil
                                animateView = false
                            } completion: {
                                deleteNoteFromContext()
                            }
                        }
                    } label: {
                        Image(systemName: selectedNote == nil ? "plus.circle.fill" : "trash.fill")
                            .font(.title2)
                            .foregroundStyle(selectedNote == nil ? Color.primary : .red)
                            .contentShape(.rect)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }

            Spacer(minLength: 0)
            ZStack {
                if isKeyboardActive {
                    Button("Done") {
                        isKeyboardActive = false
                    }
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                    .transition(.blurReplace)
                }

                if selectedNote != nil, !isKeyboardActive {
                    Button {
                        selectedNote?.allowsHitTesting = false

                        if let selectedNote,
                           selectedNote.title.isEmpty, selectedNote.content.isEmpty
                        // swiftlint:disable:next opening_brace
                        {
                            deleteNote = selectedNote
                        }

                        withAnimation(
                            /// noteAnimation is spring based thus need some delay
                            noteAnimation.logicallyComplete(after: 0.1),
                            completionCriteria: .logicallyComplete
                        ) {
                            selectedNote = nil
                            animateView = false
                        } completion: {
                            deleteNoteFromContext()
                        }
                    } label: {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.title3)
                            .foregroundStyle(Color.primary)
                            .contentShape(.rect)
                    }
                    .transition(.blurReplace)
                }
            }
        }
        .overlay {
            Text("Notes")
                .font(.callout)
                .fontWeight(.semibold)
                .opacity(selectedNote != nil ? 0 : 1)
        }
        .overlay {
            if selectedNote != nil, !isKeyboardActive {
                cardColorPicker()
                    .transition(.blurReplace)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, isKeyboardActive ? 8 : 15)
        .background(.bar)
        /// limited trigger of animation only when selectedNote is nil or not nil
        .animation(noteAnimation, value: selectedNote != nil)
        .animation(noteAnimation, value: isKeyboardActive)
    }

    @ViewBuilder
    func cardColorPicker() -> some View {
        let colorString = ["AI_grn", "AI_pink"]
        HStack(spacing: 10) {
            ForEach(1 ... colorString.count, id: \.self) { index in
                Circle()
                    .fill(getColor(from: colorString[index - 1]))
                    .frame(width: 20, height: 20)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(noteAnimation) {
                            selectedNote?.colorString = ["AI_grn", "AI_pink"].randomElement()!
                        }
                    }
            }
        }
    }

    func createEmptyNote() {
        /// Converting Image -> UIColor -> Color
        let randomColor = ["AI_grn", "AI_pink"].randomElement()!
        let note = Note(colorString: randomColor, title: "", content: "")
        context.insert(note)

        Task {
            try? await Task.sleep(for: .seconds(0))
            selectedNote = note
            selectedNote?.allowsHitTesting = true

            withAnimation(noteAnimation) {
                animateView = true
            }
        }
    }

    func deleteNoteFromContext() {
        if let deleteNote {
            context.delete(deleteNote)
            try? context.save()
            self.deleteNote = nil
        }
    }

    func getColor(from colorString: String) -> Color {
        if let image = UIImage(named: colorString) {
            return Color(image.averageColor() ?? .darkGray)
        }
        return .gray
    }
}

struct TitleNoteView: View {
    var size: CGSize
    var note: Note
    var body: some View {
        Text(note.title)
            .font(.title)
            .fontWeight(.medium)
            .foregroundStyle(.black)
            .padding(15)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .frame(width: size.width, height: size.height)
    }
}

struct DetailView: View {
    var size: CGSize
    var titleNoteSize: CGSize
    var animation: Namespace.ID
    @Bindable var note: Note
    /// View properties
    @State private var animateLayers: Bool = false /// only animate corner radius
    var body: some View {
        Rectangle()
            .fill(note.color.gradient)
            .overlay(alignment: .topLeading) {
                TitleNoteView(size: titleNoteSize, note: note)
                    .blur(radius: animateLayers ? 100 : 0)
                    .opacity(animateLayers ? 0 : 1)
            }
            .overlay {
                notesContent()
            }
            .clipShape(.rect(cornerRadius: animateLayers ? 0 : 10))
            .matchedGeometryEffect(id: note.id, in: animation)
            .transition(.offset(y: 1)) /// avoid color fade in during transition
            .allowsHitTesting(note.allowsHitTesting) // allow tap during transition
            .onChange(of: note.allowsHitTesting, initial: true) { _, newValue in
                withAnimation(noteAnimation) {
                    animateLayers = newValue
                }
            }
    }

    @ViewBuilder
    func notesContent() -> some View {
        GeometryReader {
            let currentSize: CGSize = $0.size
            // let safeArea = $0.safeAreaInsets // not always work, use UIKit way below

            VStack(alignment: .leading, spacing: 15) {
                TextField("Title", text: $note.title, axis: .vertical)
                    .font(.title)
                    .lineLimit(2)

                TextEditor(text: $note.content)
                    .font(.title)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .overlay(alignment: .topLeading) {
                        if note.content.isEmpty {
                            Text("Add a note...")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .offset(x: 8, y: 8)
                        }
                    }
            }
            .tint(.black)
            .padding(15)
            .padding(.top, safeArea.top)
            // align the size at top to avoid text wrapping during view expanding
            .frame(width: size.width, height: size.height)
            .frame(
                width: currentSize.width,
                height: currentSize.height,
                alignment: .topLeading
            )
        }
        .blur(radius: animateLayers ? 0 : 100)
        .opacity(animateLayers ? 1 : 0)
    }

    /// Safe area value (increase bottom padding for tab bar)
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }
}

/// So that the noteAnimation can use along the view
extension View {
    var noteAnimation: Animation {
        .smooth(duration: 0.3, extraBounce: 0)
    }
}

#Preview {
    GridTransitionDemoView()
}
