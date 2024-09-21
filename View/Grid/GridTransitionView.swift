//
//  GridTransitionView.swift
//  animation

import SwiftUI

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
    @State private var animateView: Bool = false
    @State private var notes: [Note] = mockNotes
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                SearchBar()
                
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                    ForEach($notes) { $note in
                        CardView(note)
                            .frame(height: 160)
                            .onTapGesture {
                                guard selectedNote == nil else { return }
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
            GeometryReader { _ in
                // need forEach to make sure selectNote == nil while transition won't confusre geoMatched animation (seeing prev card transtion is still in progress then the next selected card transtion start and overlapped)
                ForEach(mockNotes) { note in
                    if note.id == selectedNote?.id && animateView {
                        DetailView(animation: animation, note: note)
                            .ignoresSafeArea(.container, edges: .top)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar()
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
            if selectedNote?.id == note.id && animateView {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.clear)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(note.color.gradient)
                    .matchedGeometryEffect(id: note.id, in: animation)
            }
        }
    }
    
    @ViewBuilder
    func BottomBar() -> some View {
        HStack(spacing: 15) {
            Button {
                
            } label: {
                Image(systemName: selectedNote == nil ? "plus.circle.fill" : "trash.fill")
                    .font(.title2)
                    .foregroundStyle(selectedNote == nil ? Color.primary : .red)
                    .contentShape(.rect)
                    .contentTransition(.symbolEffect(.replace))
            }
            
            Spacer(minLength: 0)
            
            if selectedNote != nil {
                Button {
                    if let index = notes.firstIndex(where: { $0.id == selectedNote?.id }) {
                        notes[index].allowsHitTesting = false
                    }
                    withAnimation(noteAnimation) {
                        animateView = false
                        selectedNote = nil
                    }
                } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title3)
                        .foregroundStyle(Color.primary)
                        .contentShape(.rect)
                }
                .transition(.opacity)
            }
        }
        .overlay {
            Text("Notes")
                .font(.callout)
                .fontWeight(.semibold)
                .opacity(selectedNote != nil ? 0 : 1)
        }
        .overlay {
            if selectedNote != nil {
                CardColorPicker()
                    .transition(.blurReplace)
            }
        }
        .padding(15)
        .background(.bar)
        .animation(noteAnimation, value: selectedNote != nil) /// limited trigger of animation only when selectedNote is nil or not nil
    }
    
    @ViewBuilder
    func CardColorPicker() -> some View {
        HStack(spacing: 10) {
            ForEach(1...notes.count, id: \.self) { index in
                    Circle()
                    .fill(notes[index - 1].color.gradient)
                    .frame(width: 20, height: 20)
            }
        }
    }
}

struct DetailView: View {
    var animation: Namespace.ID
    var note: Note
    /// View properties
    @State private var animateLayers: Bool = false /// only animate corner radius
    var body: some View {
        RoundedRectangle(cornerRadius: animateLayers ? 0 : 10)
            .fill(note.color.gradient)
            .matchedGeometryEffect(id: note.id, in: animation)
            .transition(.offset(y: 1)) /// avoid color fade in during transtion
            .allowsHitTesting(note.allowsHitTesting) // allow tap during transition
            .onChange(of: note.allowsHitTesting, initial: true) { oldValue, newValue  in
                withAnimation(noteAnimation) {
                    animateLayers = newValue
                }
            }
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
