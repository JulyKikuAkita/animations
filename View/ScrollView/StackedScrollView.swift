//
//  StackedScrollView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  Composes [[View/LandingPages/StackedCards]] (a reusable generic)
//  to render a notification-centre-style stacked card scroll.
//
//  Learning point
//  ──────────────
//  Thin wrapper that demonstrates the project's `StackedCards`
//  helper in a real ScrollView context. Where `StackedCards` is
//  the engine (per-card scale/opacity/offset driven by scroll-
//  space minY via `visualEffect`), this file shows how to feed it
//  actual data with appropriate styling — `.dark` environment for
//  the iOS Notifications-style dim look, sample `Profile` data,
//  padding/spacing tuned for the stacked feel.
//
//  Reading order: read `View/LandingPages/StackedCards.swift` FIRST
//  for the mechanics; this file is then easy to follow as a consumer.
//
//  Key APIs
//  ────────
//  • `StackedCards<Content, Data>` (consumer-facing helper from
//    LandingPages) — the actual engine.
//  • `.environment(\.colorScheme, .dark)` — pins the dark
//    Notifications-style look regardless of system setting.
//  • Sample-data `Profile` from `Model/Profile.swift`.
//
//  How to apply
//  ────────────
//  Use as a guide for feeding your own Identifiable model into
//  `StackedCards`. For the actual stack mechanic, lift the engine
//  from LandingPages.
//
//  See also
//  ────────
//  • View/LandingPages/StackedCards.swift — the engine.
//  • View/Carousel/LoopingStackCardsDemoView.swift — different
//    "stack" pattern (drag-to-advance, iOS 18 Group(subviews:)).
//
import SwiftUI

struct StackedScrollDemoView: View {
    var body: some View {
        ZStack {
            GeometryReader { _ in
                Image(.IMG_0215)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                StackedScrollView()
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

struct StackedScrollView: View {
    var body: some View {
        VStack {
            StackedCards(
                items: stackCards,
                stackedDisplayCount: 1,
                opacityDisplayCount: 0,
                itemHeight: 70
            ) { item in
                stackCardView(item)
            }
            .padding(.bottom, 20)

            bottomActionBar()
        }
        .padding(20)
    }

    @ViewBuilder
    func stackCardView(_ item: Profile) -> some View {
        if item.username.isEmpty {
            Rectangle()
                .fill(.clear)

        } else {
            HStack(spacing: 12) {
                Image(item.profilePicture)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4, content: {
                    Text(item.username)
                        .font(.callout)
                        .fontWeight(.bold)

                    Text(item.lastMsg)
                        .font(.caption)
                        .lineLimit(1)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .frame(maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 20))
        }
    }

    @ViewBuilder
    func bottomActionBar() -> some View {
        HStack {
            Button(action: {}, label: {
                Image(systemName: "flashlight.off.fill")
                    .font(.title3)
                    .frame(width: 35, height: 35)
            })
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .buttonBorderShape(.circle)

            Spacer(minLength: 0)

            Button(action: {}, label: {
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .frame(width: 35, height: 35)
            })
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .buttonBorderShape(.circle)
        }
    }
}

#Preview {
    StackedScrollDemoView()
}
