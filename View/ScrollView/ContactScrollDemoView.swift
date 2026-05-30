//
//  ContactScrollDemoView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 17+ — `onScrollGeometryChange`, `onScrollPhaseChange`,
//  `coordinateSpace(.named(...))`.
//
//  Learning point
//  ──────────────
//  iOS Contacts–style alphabetic scroll index: a vertical contact
//  list with sticky letter headers, plus a draggable indicator
//  capsule on the trailing edge that lets the user fast-jump to any
//  letter section.
//
//  Three pieces working together:
//    1. Vertical `ScrollView` with `pinnedViews: [.sectionHeaders]`
//       so the letter headers stick to the top as the user scrolls
//       past their section.
//    2. `CustomScrollIndicator` — the draggable trailing capsule.
//       Computes its y-position from `contentOffset.y / contentHeight`;
//       lets the user drag it directly to scrub the entire list.
//    3. Two-way binding: `onScrollGeometryChange` drives indicator
//       from scroll, `DragGesture` drives scroll from indicator.
//       Bidirectional binding is the load-bearing UX bit — if
//       either direction fights the other the index "judders."
//
//  Key APIs
//  ────────
//  • `onScrollGeometryChange(for: ScrollGeometry.self)` — drives
//    the indicator position from scroll state. The file extends
//    `ScrollGeometry` with `scrollOffsetY` / `contentHeight` helpers.
//  • `onScrollPhaseChange` — settle detection; the indicator fades
//    out when scrolling stops.
//  • `coordinateSpace(.named(...))` + `containerRelativeFrame` —
//    named coordinate space lets the indicator compute its
//    position correctly across scroll bounds.
//  • `DragGesture` on the indicator — translates raw gesture into
//    a scroll offset.
//
//  How to apply
//  ────────────
//  Reach for this when a long alphabetised list (contacts, music
//  library, countries) needs faster navigation than scroll-by-flick.
//  The custom indicator beats native scrollbars for branded UIs
//  because it can carry a letter label.
//
//  See also
//  ────────
//  • View/ScrollView/CustomHeaderEffect/* — sticky-header siblings.
//
import SwiftUI

struct ContactSection: Identifiable {
    var id: String
    var contacts: [Contact]

    static func generateData() -> [ContactSection] {
        Dictionary(grouping: dummyContacts) {
            String($0.name.first ?? "A")
        }.compactMap {
            .init(id: $0.key, contacts: $0.value)
        }.sorted { $0.id < $1.id }
    }
}

struct ContactScrollDemoView: View {
    var body: some View {
        ContactScrollView()
    }
}

struct ContactScrollView: View {
    @State private var sections: [ContactSection] = ContactSection.generateData()
    /// View Properties
    @State private var scrollProperties: ScrollGeometry = .init(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(),
        containerSize: .zero
    )
    @State private var activeID: String = "A"

    /// scroll state - active, idle, animating, decelerating etc
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var scrollPosition: ScrollPosition = .init()

    /// Gesture properties
    @State private var previousScrollProgress: CGFloat?
    @GestureState private var isGestureActive: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 12) {
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
                .padding(20)
                .padding(.bottom, scrollProperties.containerSize.height - 250)
            }
            .background(.gray.opacity(0.15))
            .navigationTitle("Contacts")
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: ScrollGeometry.self) {
                $0
            } action: { _, newValue in
                scrollProperties = newValue
            }
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
            }
            .scrollPosition($scrollPosition)
        }
        .overlay(alignment: .trailing) {
            customScrollIndicator()
        }
    }

    func sectionView(_ section: ContactSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.id)
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 15) {
                ForEach(section.contacts) { contact in
                    Text(contact.name)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    /// Skip divider for the last item
                    if contact.id != section.contacts.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(15)
        .background(.background, in: .rect(cornerRadius: 10))
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .scrollView(axis: .vertical))
        } action: { newValue in
            /// At top
            if newValue.minY >= 0, newValue.minY < 150 {
                activeID = section.id
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func customScrollIndicator() -> some View {
        GeometryReader { geometry in
            let indicatorHeight: CGFloat = 40
            /// Calculating Progress
            let scrollProgress = max(min(scrollProperties.scrollOffsetY / scrollProperties.contentHeight, 1), 0)
            /// Calculating Indicator Offset
            ///  Since the offset starts from the top
            let indicatorOffset = (geometry.size.height - indicatorHeight) * scrollProgress
            let showPopup = scrollPhase != .idle || isGestureActive

            ZStack(alignment: .top) {
                Capsule()
                    .fill(.background.shadow(.drop(color: .black.opacity(0.2), radius: 10, x: 0, y: 0)))
                    .padding(.trailing, 5)

                Capsule()
                    .fill(.blue.gradient)
                    .frame(height: indicatorHeight)
                    .padding(.trailing, 5)
                    .contentShape(.rect)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("INDICATORVIEW"))
                            .updating($isGestureActive, body: { _, out, _ in
                                out = true
                            })
                            .onChanged { value in
                                if previousScrollProgress == nil {
                                    previousScrollProgress = scrollProgress
                                }

                                guard let previousScrollProgress else { return }
                                /// calculating drag progress
                                let dragProgress = value.translation.height / (geometry.size.height - indicatorHeight)
                                let endProgress = max(min(previousScrollProgress + dragProgress, 1), 0)

                                /// Scrolling Content
                                scrollPosition.scrollTo(y: endProgress * scrollProperties.contentHeight)
                            }
                    )
                    .offset(y: indicatorOffset)
                    .onChange(of: isGestureActive) { _, newValue in
                        if !newValue {
                            previousScrollProgress = nil
                        }
                    }
            }
            .overlay(alignment: .topLeading) {
                ZStack {
                    if showPopup {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 50,
                            bottomLeadingRadius: 50,
                            bottomTrailingRadius: 5,
                            topTrailingRadius: 50,
                            style: .continuous
                        )
                        .fill(.blue.gradient)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Text(activeID)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                        }
                        .compositingGroup()
                        .offset(x: -55, y: indicatorOffset - 10)
                    }
                }
                .offset(y: isGestureActive ? -50 : 0)
                .animation(.easeInOut(duration: 0.25), value: isGestureActive)
            }
            .animation(.easeInOut(duration: 0.25), value: showPopup)
        }
        .frame(width: 13)
        .containerRelativeFrame(.vertical) { value, _ in
            value * 0.5
        }
        .coordinateSpace(.named("INDICATORVIEW"))
    }
}

#Preview {
    ContactScrollDemoView()
}

extension ScrollGeometry {
    var scrollOffsetY: CGFloat {
        contentOffset.y + contentInsets.top
    }

    var contentHeight: CGFloat {
        contentSize.height - containerSize.height
    }
}
