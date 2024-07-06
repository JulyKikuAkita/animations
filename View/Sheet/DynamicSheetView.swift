//
//  DynamicSheetView.swift
//  animation


import SwiftUI

struct DynamicSheetDemoView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

struct DynamicSheetView: View {
    /// View Properties
    @State private var showSheet: Bool = false
    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        VStack {
            Spacer()
            
            Button("Show Sheet") {
                showSheet.toggle()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(30)
        .sheet(
isPresented: $showSheet,
 onDismiss: {
            
        },
 content: {
            /// Sheet View
            GeometryReader(content: { geometry in
                let size = geometry.size
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        onBoarding(size)
                    }
                    /// required for paging scrollview
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            })
            /// Custom Presentation update
            .presentationCornerRadius(30)
            .presentationDetents(
                sheetHeight == .zero ? [.medium] : [.height(sheetHeight)]
            )
            /// disabling swipe to dismiss
            .interactiveDismissDisabled()
        })
    }
    
    /// First View for Sheet
    @ViewBuilder
    func onBoarding(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12, content: {
            Text("Know Everything\nabout the weather")
                .font(.largeTitle.bold())
                .lineLimit(2)
            
            /// Custom Attribute Subtitle
            Text(attributeSubTitle)
                .font(.callout)
                .foregroundStyle(.gray)
        })
        .padding(15)
        .padding(.horizontal, 15)
        .padding(.top, 15)
        .padding(.bottom, 130)
        .frame(width: size.width, alignment: .leading)
        /// Finding the view's height
    }
    
    var attributeSubTitle: AttributedString {
        let string = "Start now and learn more about the Abyss instantly."
        var attString = AttributedString(stringLiteral: string)
        if let range = attString.range(of: "Abyss") {
            attString[range].foregroundColor = .black
            attString[range].font = .callout.bold()
        }
        return attString
    }
}

#Preview {
    DynamicSheetView()
}
