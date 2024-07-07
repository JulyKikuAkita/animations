//
//  DynamicSheetView.swift
//  animation
// wip: 14:0 0https://www.youtube.com/watch?v=Y4Vm61vrhTE&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=28

import SwiftUI

struct DynamicSheetDemoView: View {
    var body: some View {
        NavigationStack {
            DynamicSheetView()
        }
    }
}

struct DynamicSheetView: View {
    /// View Properties
    @State private var showSheet: Bool = false
    @State private var sheetHeight: CGFloat = .zero
    @State private var emailAddress: String = ""
    @State private var password: String = ""

    /// Storing Sheet's height for swipe calculation
    @State private var sheetFirstPageHeight: CGFloat = .zero
    @State private var sheetSecondPageHeight: CGFloat = .zero
    @State private var sheetScrollProgress: CGFloat = .zero

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
        .sheet(isPresented: $showSheet, 
               onDismiss: {},
               content: {
            /// Sheet View
            GeometryReader(content: { geometry in
                let size = geometry.size
                ScrollViewReader(content: { proxy in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 0) {
                            OnBoardingView(size)
                                .id("First Page")
                            
                            LoginView(size)
                                .id("Second Page")
                        }
                        /// required for paging scrollview
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            if sheetScrollProgress < 1 {
                                withAnimation(.snappy) {
                                    proxy.scrollTo("Second Page", anchor: .leading)
                                }
                            } else {
                                /// implementation for continue button
                                withAnimation(.snappy) {
                                    showSheet.toggle()
                                }
                            }
                        }, label: {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .opacity(1 - sheetScrollProgress)
                                /// adding extra width for 2nd bottom sheet
                                .frame(width: 120 + (sheetScrollProgress * 50))
                                .overlay {
                                    /// Next page text
                                    HStack(spacing: 8) {
                                        Text("Get Started")
                                        
                                        Image(systemName: "arrow.right")
                                    }
                                    .fontWeight(.semibold)
                                    .opacity(sheetScrollProgress)
                                }
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(
                                    .linearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing), in: .capsule)
                        })
                        .padding(15)
                        .offset(y: sheetHeight - 100)
                        /// Moving button near to the next view
                        .offset(y: sheetScrollProgress * -120) /// Sec view height 220 - first view height 100
                    }
                })
               
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
    func OnBoardingView(_ size: CGSize) -> some View {
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
        .heightChangePreference { height in
            sheetFirstPageHeight = height
            /// Since the first sheet height will be the same as the initial page height
            sheetHeight = height
        }
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
    
    /// Second View for Sheet
    @ViewBuilder
    func LoginView(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Descend to abyss")
                .font(.largeTitle.bold())
            
            CustomTextField(hint: "Email address", text: $emailAddress, icon: "envelope")
                .padding(.top, 20)
            
            CustomTextField(
                hint: "*****",
                text: $password,
                icon: "lock",
                isPasswordField: true
            )
                .padding(.top, 20)
        }
        .padding(15)
        .padding(.horizontal, 10)
        .padding(.top, 15)
        .padding(.bottom, 220)
        .frame(width: size.width)
        .overlay {
            Text("\(sheetScrollProgress)")
        }
        /// Finding the view's height
        .heightChangePreference { height in
            sheetSecondPageHeight = height
        }
        /// Offset preference
        .minXChangePreference { minX in
            let diff = sheetSecondPageHeight - sheetFirstPageHeight
            /// size between ( 0 to screen width )
            let truncatedMinX = min(size.width - minX, size.width)
            guard truncatedMinX > 0 else { return }
            /// Converting minX to progress [0, 1]
            let progress = truncatedMinX / size.width
            sheetScrollProgress = progress
            /// Adding difference height to sheet height
            sheetHeight = sheetFirstPageHeight + (diff * progress)
        }
    }
}

#Preview {
    DynamicSheetDemoView()
}

private struct CustomTextField: View {
    var hint: String
    @Binding var text: String
    var icon: String
    var isPasswordField: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isPasswordField {
                SecureField(hint, text: $text)
            } else {
                TextField(hint, text: $text)
            }
            
            Divider()
        }
        .overlay(alignment: .trailing) {
            Image(systemName: icon)
                .foregroundStyle(.gray)
        }
    }
}
