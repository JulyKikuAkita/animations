//
//  GridTransitionView.swift
//  animation

import SwiftUI
import SwiftData

@main
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

    /// Swift data
//    @Query(sort: [.init(\Note.dateCreated, order: .reverse)], animation: .snappy)
//    private var notes: [Note] /// no need for state object as swift data model directly update to the object
    @Environment(\.modelContext) private var context
    var body: some View {
        SearchQueryView(searchText: searchText) { notes in
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    SearchBar()
                    
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                        ForEach(notes) { note in
                            CardView(note)
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
                GeometryReader { proxy  in
                    let size = proxy.size
                    // need forEach to make sure selectNote == nil while transition won't confuse geoMatched animation (seeing prev card transition is still in progress then the next selected card transition start and overlapped)
                    ForEach(notes) { note in
                        if note.id == selectedNote?.id && animateView {
                            DetailView(size: size, titleNoteSize: titleNoteSize, animation: animation, note: note)
                                .ignoresSafeArea(.container, edges: .top)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomBar()
            }
            .focused($isKeyboardActive) // this modifier applies to detailView which has text field too
        }
    }
    
    @ViewBuilder
    func SearchBar() -> some View {
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
    func CardView(_ note: Note) -> some View {
        ZStack {
            /// expanded
            if selectedNote?.id == note.id && animateView {
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
    func BottomBar() -> some View {
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
                                noteAnimation.logicallyComplete(after: 0.1), /// noteAnimation is spring based thus need some delay
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
                
                if selectedNote != nil && !isKeyboardActive{
                    Button {
                        // no more need this when using swift data as it's reflecting to object direclty
    //                    if let index = notes.firstIndex(where: { $0.id == selectedNote?.id }) {
    //                        notes[index].allowsHitTesting = false
    //                    }
                        selectedNote?.allowsHitTesting = false
                        
                        if let selectedNote, (
                            selectedNote.title.isEmpty && selectedNote.content.isEmpty
                        ) {
                            deleteNote = selectedNote
                        }
                        
                        withAnimation(
                            noteAnimation.logicallyComplete(after: 0.1), /// noteAnimation is spring based thus need some delay
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
            if selectedNote != nil && !isKeyboardActive {
                CardColorPicker()
                    .transition(.blurReplace)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, isKeyboardActive ? 8 : 15)
        .background(.bar)
        .animation(noteAnimation, value: selectedNote != nil) /// limited trigger of animation only when selectedNote is nil or not nil
        .animation(noteAnimation, value: isKeyboardActive)
    }
    
    @ViewBuilder
    func CardColorPicker() -> some View {
        let colorString = ["AI_grn", "AI_pink"]
        HStack(spacing: 10) {
            ForEach(1...colorString.count, id: \.self) { index in
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
                NotesContent()
            }
            .clipShape(.rect(cornerRadius: animateLayers ? 0 : 10))
            .matchedGeometryEffect(id: note.id, in: animation)
            .transition(.offset(y: 1)) /// avoid color fade in during transition
            .allowsHitTesting(note.allowsHitTesting) // allow tap during transition
            .onChange(of: note.allowsHitTesting, initial: true) { oldValue, newValue  in
                withAnimation(noteAnimation) {
                    animateLayers = newValue
                }
            }
    }
    
    @ViewBuilder
    func NotesContent() -> some View {
        GeometryReader {
            let currentSize: CGSize = $0.size
            //let safeArea = $0.safeAreaInsets // not always work, use UIKit way below
            
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
            .frame(width: size.width, height: size.height) // align the size at top to avoid text wrapping during view expanding
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
