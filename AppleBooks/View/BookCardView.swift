//
//  BookCardView.swift
//  animation
//
/*
 Use @ViewBuilder when the function might return multiple views or conditional views.
 Omit @ViewBuilder when the function always returns a single, self-contained view.
 // @ViewBuilder is necessary because Text and Image are separate views.
 @ViewBuilder func DynamicView(isEnabled: Bool) -> some View {
    if isEnabled {
        Text("Enabled")
        Image(systemName: "checkmark.circle")
    } else {
        Text("Disabled")
    }
 }
 */
import SwiftUI

struct BookCardView: View {
    var book: Book
    var parentHorizontalPadding: CGFloat = 15
    var size: CGSize
    var isScrolled: (Bool) -> Void
    /// Scroll animation properties
    /// Adding these insets to the content size of the scroll view
    /// will give you the total scrollable space of the scroll view.
    @State private var scrollProperties: ScrollGeometry =
        .init(
            contentOffset: .zero,
            contentSize: .zero,
            contentInsets: .init(),
            containerSize: .zero
        )
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var isPageScrolled: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 15) {
                topCardView()
                    .containerRelativeFrame(.vertical) { value, _ in
                        value * 0.9
                    }

                otherTextContents()
                    .padding(.horizontal, 15)
                    .frame(maxWidth: size.width - (parentHorizontalPadding * 2)) /// due to apply negative padding
                    .padding(.bottom, 50)
            }
            /// scrolling + zoom effect: apply a negative scale to the horizontal padding
            /// combine with .scrollClipDisabled()
            /// 15 is the current view horizontal padding
            /// Note: negative padding increase view size, so need to get maxWidth of geometry Width - 15 * 2 to the text view
            .padding(.horizontal, -parentHorizontalPadding * scrollProperties.topInsetProgress)
        }
        .scrollPosition($scrollPosition)
        .scrollClipDisabled()
        .onScrollGeometryChange(for: ScrollGeometry.self, of: {
            $0
        }, action: { _, newValue in
            scrollProperties = newValue
            isPageScrolled = newValue.offsetY > 0
        })
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(BookScrollEnd(topInset: scrollProperties.contentInsets.top))
        .onChange(of: isPageScrolled) { _, newValue in
            isScrolled(newValue)
        }
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 15,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 15
            )
            .fill(.background)
            .ignoresSafeArea(.all, edges: .bottom)
            .offset(y: scrollProperties.offsetY > 0 ? 0 : -scrollProperties.offsetY)
            .padding(.horizontal, -parentHorizontalPadding * scrollProperties.topInsetProgress)
        }
    }

    func topCardView() -> some View {
        VStack(spacing: 15) {
            fixedHeaderView()

            /// Main content
            Image(book.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top, 10)

            Text(book.title)
                .serifText(.title2, weight: .bold)

            Button {} label: {
                HStack(spacing: 6) {
                    Text(book.author)

                    Image(systemName: "chevron.right")
                        .font(.callout)
                }
            }.padding(.top, -5)

            Label(book.rating, systemImage: "star.fill")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Book")
                        .fontWeight(.semibold)

                    Image(systemName: "info.circle")
                        .font(.caption)
                }

                Text("45 Pages")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button {} label: {
                        Label("Sample", systemImage: "book.pages")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .tint(.white.opacity(0.2))

                    Button {} label: {
                        Text("Get")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 5)
            }
            .padding(15)
            .background(.white.opacity(0.2), in: .rect(cornerRadius: 15))
        }
        .foregroundStyle(.white)
        .padding(15)
        .frame(maxWidth: size.width - parentHorizontalPadding * 2) /// due to apply negative padding
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(book.color.gradient)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 15,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 15
            )
        )
    }

    func otherTextContents() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From the Publisher")
                .serifText(.title3, weight: .semibold)

            Text([paragraph1, paragraph2].randomElement() ?? paragraph2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(5)

            Text("Requirements")
                .serifText(.title3, weight: .semibold)
                .padding(.top, 15)

            /// Mock Requirement View
            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Books")

                Text("Requires iOS 12 or macOS 10.14 or later")
                    .foregroundStyle(.secondary)

                Text("iBooks")
                    .padding(.top, 5)

                Text("Requires iBooks 3 or macOS 10.14 or later")
                    .foregroundStyle(.secondary)

                Text("Versions")
                    .font(.title3)
                    .fontDesign(.serif)
                    .fontWeight(.semibold)
                    .padding(.top, 25)

                Text("Updated Mar 16 2022")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }

    func fixedHeaderView() -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    scrollPosition.scrollTo(edge: .top)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }

            Spacer()

            Button {} label: {
                Image(systemName: "plus.circle.fill")
            }

            Button {} label: {
                Image(systemName: "ellipsis.circle.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.title)
        .foregroundStyle(.white, .white.tertiary)
        .background {
            GeometryReader { geometry in
                TransparentBlurView()
                    .frame(height: scrollProperties.contentInsets.top + 50)
                    .blur(radius: 10, opaque: false)
                    .frame(height: geometry.size.height, alignment: .bottom)
            }
            .opacity(scrollProperties.topInsetProgress)
        }
        .padding(.horizontal, -parentHorizontalPadding * scrollProperties.topInsetProgress) /// fix header position during scroll
        .offset(y: scrollProperties.offsetY < 20 ? 0 : scrollProperties.offsetY - 20)
        .zIndex(1000)
    }
}

#Preview {
    GeometryReader { geometry in
        BookCardView(book: dummyBooks[0], parentHorizontalPadding: 15, size: geometry.size) { _ in
        }
        .padding(.horizontal, 15)
    }
    .background(.gray.opacity(0.15))
}

struct BookScrollEnd: ScrollTargetBehavior {
    var topInset: CGFloat
    func updateTarget(_ target: inout ScrollTarget, context _: TargetContext) {
        if target.rect.minY < topInset {
            target.rect.origin = .zero
        }
    }
}

extension View {
    func serifText(_ font: Font, weight: Font.Weight) -> some View {
        self
            .font(font)
            .fontDesign(.serif)
            .fontWeight(weight)
    }
}

private extension ScrollGeometry {
    var offsetY: CGFloat {
        contentOffset.y + contentInsets.top
    }

    /// provide [0, 1] value to indicate top of the scrollView reaches the top of the screen
    /// 0: initial position
    /// 1: top edge reached top of the screen
    var topInsetProgress: CGFloat {
        guard contentInsets.top > 0 else { return 0 }
        return max(min(offsetY / contentInsets.top, 1), 0)
    }
}
