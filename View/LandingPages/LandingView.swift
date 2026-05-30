//
//  LandingView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Onboarding carousel with a MORPHING SF Symbol at the top: as the
//  user advances through pages, the hero symbol smoothly transitions
//  to the next icon (e.g. `globe.americas` → `airplane.departure`)
//  while title/subtitle slide horizontally. Page advance is
//  BUTTON-driven, not swipe — every transition is intentional.
//
//  The morphing symbol uses `MorphingSymbolView` (project helper),
//  which renders SF Symbols via `Image(systemName:)` with
//  `.contentTransition(.symbolEffect(.replace))` plus a hand-tuned
//  fade that hides SwiftUI's default "swap glyph in place" jump.
//
//  Slide mechanics
//  ───────────────
//  Single horizontal `HStack` of N pages, sized to N×screen-width.
//  An `.offset(x: -CGFloat(activePage.index) * size.width)` shifts
//  the whole stack left to put the active page on screen, animated
//  with `.smooth(duration: 0.6, extraBounce: 0.1)`. No ScrollView —
//  cleaner than fighting `.tabViewStyle(.page)`'s scroll gestures.
//
//  Key APIs
//  ────────
//  • `MorphingSymbolView` — project helper for animated symbol
//    transitions. Where the magic lives.
//  • `.smooth(duration:extraBounce:)` — the unifying animation curve;
//    `extraBounce` makes it feel less mechanical without the
//    overshoot of `.bouncy`.
//  • `.contentTransition(.identity)` on the title — opt OUT of
//    SwiftUI's default text content-transition so our custom slide
//    is the only motion.
//  • Manual page-indicator dots, sized via `scale` derived from
//    distance to active index.
//
//  How to apply
//  ────────────
//  Use as a template for any "tap-through" onboarding (vs.
//  swipe-through). For permission-specific onboarding, see
//  [[PermissionOnboardingIOS26]]. For an in-bezel app-preview
//  onboarding, see [[OnBoardingiOS26View]].
//
//  See also
//  ────────
//  • OnBoardingiOS26View.swift — sibling, iOS 26-styled onboarding
//    with simulator-bezel mockup.
//  • PermissionOnboardingIOS26.swift — sibling focused on permission
//    request flow.
//
import SwiftUI

struct LandingView: View {
    var body: some View {
        MorphingSymbolDemoView()
            .environment(\.colorScheme, .dark)
    }
}

struct MorphingSymbolDemoView: View {
    /// View Properties
    @State private var activePage: Page = .page1
    var body: some View {
        GeometryReader {
            let size = $0.size

            VStack {
                Spacer(minLength: 0)
                MorphingSymbolView(
                    symbol: activePage.rawValue,
                    config: .init(
                        font: .system(size: 150, weight: .bold),
                        frame: CGSize(width: 250, height: 200),
                        radius: 30,
                        foregroundColor: .white
                    )
                )

                textContent(size: size)

                Spacer(minLength: 0)

                indicatorView()

                continueButton()
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                headerView()
            }
        }
        .background {
            Rectangle()
                .fill(.black.gradient)
                .ignoresSafeArea()
        }
    }

    func headerView() -> some View {
        HStack {
            Button {
                activePage = activePage.previousPage
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .contentShape(.rect)
            }
            .opacity(activePage != .page1 ? 1 : 0)

            Spacer(minLength: 0)

            Button("Skip") {
                activePage = .page4
            }
            .fontWeight(.semibold)
            .opacity(activePage != .page4 ? 1 : 0)
        }
        .foregroundStyle(.white)
        .animation(.snappy(duration: 0.35, extraBounce: 0), value: activePage)
        .padding(15)
    }

    func indicatorView() -> some View {
        HStack(spacing: 6) {
            ForEach(Page.allCases, id: \.rawValue) { page in
                Capsule()
                    .fill(.white.opacity(activePage == page ? 1 : 0.4))
                    .frame(width: activePage == page ? 25 : 8, height: 8)
            }
        }
        .animation(.smooth(duration: 0.5, extraBounce: 0), value: activePage)
        .padding(.bottom, 12)
    }

    func textContent(size: CGSize) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Page.allCases, id: \.rawValue) { page in
                    Text(page.title)
                        .lineLimit(1)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .kerning(1.1) // spacing between chars, 0 is default
                        .frame(width: size.width)
                }
            }
            /// sliding text view left/right based on the current active page
            .offset(x: -activePage.index * size.width)
            .animation(.smooth(duration: 0.7, extraBounce: 0.1), value: activePage)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Page.allCases, id: \.rawValue) { page in
                    Text(page.subTitle)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.gray)
                        .frame(width: size.width)
                }
            }
            .offset(x: -activePage.index * size.width)
            /// adding delay from main subject
            .animation(.smooth(duration: 0.9, extraBounce: 0.1), value: activePage)
        }
        .padding(.top, 15)
        .frame(width: size.width, alignment: .leading)
    }

    func continueButton() -> some View {
        Button {
            activePage = activePage.nextPage
        } label: {
            Text(activePage == .page4 ? "Start playing" : "Continue")
                .contentTransition(.identity)
                .foregroundStyle(.black)
                .padding(.vertical, 15)
                .frame(maxWidth: activePage == .page1 ? 220 : 180)
                .background(.white, in: .capsule)
        }
        .padding(.bottom, 15)
        .animation(.smooth(duration: 0.5, extraBounce: 0), value: activePage)
    }
}

#Preview {
    LandingView()
}
