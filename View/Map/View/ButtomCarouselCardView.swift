//
//  ButtomCarouselCardView.swift
//  animation
//
//  Created on 11/30/25.
import MapKit
import SwiftUI

struct ButtomCarouselCardView: View {
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
