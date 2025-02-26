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
    var size: CGSize
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 15) {
                TopCardView()
                    .containerRelativeFrame(.vertical) { value, _ in
                        value * 0.9
                    }
                
                OtherTextContents()
            }
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
        }
    }
    
    func TopCardView() -> some View {
        VStack(spacing: 15) {
            FixedHeaderView()
            
            /// Main content
            Image(book.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top, 10)
            
            Text(book.title)
                .serifText(.title2, weight: .bold)
            
            Button {
                
            } label: {
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
                    Button {
                        
                    } label: {
                        Label("Sample", systemImage: "book.pages")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .tint(.white.opacity(0.2))
                    
                    Button {
                        
                    } label: {
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
    
    func OtherTextContents() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From the Publisher")
                .serifText(.title3, weight: .semibold)
            
            Text(paragraph1)
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
    
    func FixedHeaderView() -> some View {
        HStack(spacing: 10) {
            Button {
                
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            
            Spacer()
            
            Button {
                
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            
            Button {
                
            } label: {
                Image(systemName: "ellipsis.circle.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.title)
        .foregroundStyle(.white, .white.tertiary)
    }
}

#Preview {
    GeometryReader { geometry in
        BookCardView(book: dummyBooks[0], size: geometry.size)
    }
    .padding(.horizontal, 15)
    .background(.gray.opacity(0.15))
}

extension View {
    func serifText(_ font: Font, weight: Font.Weight) -> some View {
        self
            .font(font)
            .fontDesign(.serif)
            .fontWeight(weight)
    }
}
