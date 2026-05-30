//
//  BottomCarouselCardView.swift
//  animation
//
//  Created on 11/30/25.
//
//  ⚠️  REUSABLE HELPER, NOT A STANDALONE DEMO. Consumed by
//      [[CustomMapView]] (lines ~85 and ~130) as the per-place
//      card inside the map's bottom carousel. Don't rename or
//      remove without updating that file.
//
//  Learning point
//  ──────────────
//  Card view with a TWO-MODE rendering: when given a real `Place`,
//  it shows actual data (name, address, phone link, "Learn More"
//  button); when given `nil`, it shows a redacted placeholder via
//  `.redacted(reason: .placeholder)` + `.disabled(true)`.
//
//  This dual-mode pattern is the takeaway: don't write a separate
//  `LoadingCardView` and `LoadedCardView`. Pass `nil` and let
//  `.redacted(reason: .placeholder)` shimmer the same view tree.
//  The card's layout, padding, and material chrome stay constant
//  between states — only the data binding changes — so users see a
//  smooth "skeleton fills in" rather than a layout shift on load.
//
//  Why `.redacted(reason: .placeholder)` over a custom shimmer?
//  ────────────────────────────────────────────────────────────
//  System-managed: gets the right shimmer treatment automatically,
//  respects accessibility settings, and ensures Dynamic Type still
//  shapes the placeholder correctly. Pair with `.disabled(true)`
//  so taps don't fall through to a not-yet-loaded button action.
//
//  Key APIs
//  ────────
//  • `.redacted(reason: .placeholder)` — system shimmer for
//    skeleton states.
//  • `.disabled(true)` — kills hit-testing on the placeholder
//    branch.
//  • `Link(_:destination:)` — wraps a URL in a tappable label
//    (used here for `tel:` phone links).
//  • `.optionalGlassEffect(_:)` — project helper that applies
//    iOS 26 `.glassEffect` when available, falls back to a
//    materialised background pre-iOS 26.
//  • `@Binding var expandedItem: Place?` — writes back to the
//    parent so the carousel can present a sheet for the tapped
//    place.
//
//  How to apply
//  ────────────
//  Reuse the `data?` parameter pattern any time a card view has
//  real-data and loading-skeleton variants. Don't fork the
//  view; let `nil` drive the redaction.
//
//  See also
//  ────────
//  • CustomMapView.swift — the consumer.
//
import MapKit
import SwiftUI

struct BottomCarouselCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    var place: Place?
    @Binding var expandedItem: Place?
    let inwardPadding: CGFloat = 15
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let place {
                Group {
                    Text(place.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(place.address)
                        .lineLimit(2)

                    if let phoneNumber = place.phoneNumber,
                       let url = URL(string: "tel: \(phoneNumber)")
                    {
                        Link("Phone Number: **\(phoneNumber)**", destination: url)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer(minLength: 0)

                    Button {
                        expandedItem = place
                    } label: {
                        Text("Learn More")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .buttonBorderShape(.capsule)
                }
            } else {
                /// Dummy placeholder items
                Group {
                    Text("PLACEHOLDER NAME")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("This is a placeholder address. Replace with actual address.")
                        .lineLimit(2)

                    Text("xxx-xxx-xxxx")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Spacer(minLength: 0)

                    Button {} label: {
                        Text("Learn More")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .buttonBorderShape(.capsule)
                }
                .disabled(true)
                .redacted(reason: .placeholder)
            }
        }
        .padding(15)
        .optionalGlassEffect(colorScheme)
    }
}
