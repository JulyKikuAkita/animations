//
//  GridImageDetailContentView.swift
//  demoApp

import SwiftUI

struct GridImageDetailContentView: View {
    var body: some View {
        LazyVStack(spacing: 15) {
            DummySection(title: "Social Media")
            DummySection(title: "Sales", isLong: true)

            ImageView("IMG_2104")
            DummySection(title: "Business")
            DummySection(title: "Promotion", isLong: true)

            ImageView("IMG_1915")
            DummySection(title: "YouTube")
            DummySection(title: "Twitter (X)")
            DummySection(title: "Marketing Campaign", isLong: true)

            ImageView("fox")
            DummySection(title: "Conclusion", isLong: true)
        }
        .padding(15)
    }

    @ViewBuilder
    func DummySection(title: String, isLong _: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8, content: {
            Text(title)
                .font(.title.bold())

            Text(dummyDescription)
                .multilineTextAlignment(.leading)
                .kerning(1.2)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func ImageView(_ image: String) -> some View {
        GeometryReader {
            let size = $0.size
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
        }
        .frame(height: 400)
    }
}

#Preview {
    GridImageDetailContentView()
}
