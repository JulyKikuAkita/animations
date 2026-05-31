//
//  DynamicSheetView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 15+ baseline — uses custom `PreferenceKey`s for geometry
//  rather than the iOS 16+ `onGeometryChange`. Predates the modern
//  `[[DynamicHeightSheetViewiOS26]]` approach.
//
//  Learning point
//  ──────────────
//  Two-page horizontally-paging onboarding sheet (intro → login /
//  signup) where the sheet's HEIGHT and CTA TEXT change per page,
//  with keyboard awareness for the form page. The most pre-iOS-16
//  thing in this folder: custom `PreferenceKey`s
//  (`heightChangePreference`, `minXChangePreference`) publish
//  geometry up the view tree because `onGeometryChange` didn't
//  exist yet.
//
//  Read this file for the historical pattern (PreferenceKeys are
//  still useful where iOS 16+ APIs don't cover); for new code,
//  prefer [[DynamicHeightSheetViewiOS26]] — same problem, less
//  ceremony.
//
//  Key APIs
//  ────────
//  • Custom `PreferenceKey`s — pre-iOS-16 way to bubble geometry
//    measurements up the view tree.
//  • `.scrollTargetBehavior(.paging)` — paged horizontal scroll
//    between intro / form.
//  • `.sheet(onDismiss:)` with state-reset closure — clean
//    separation of "dismissed mid-flow" vs. "completed."
//  • `.interactiveDismissDisabled()` — gates pull-to-dismiss while
//    the form is partially filled.
//  • `UIResponder` keyboard notifications — pre-iOS 26 way to
//    track keyboard height.
//  • `AttributedString` — rich-text legal copy.
//
//  How to apply
//  ────────────
//  Reach for the PreferenceKey pattern when you need geometry
//  measurements pre-iOS 16, OR for cases the modern modifiers
//  don't cover. For everything else, use the iOS 26 path.
//
//  See also
//  ────────
//  • DynamicHeightSheetViewiOS26.swift — modern replacement using
//    `onGeometryChange` + custom `Animatable` modifier.
//  • DynamicFloatingSheetsiOS18View.swift — multi-step in-place
//    swap; different goal.
//
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
    @State private var hasAccount: Bool = false

    /// Storing Sheet's height for swipe calculation
    @State private var sheetFirstPageHeight: CGFloat = .zero
    @State private var sheetSecondPageHeight: CGFloat = .zero
    @State private var sheetScrollProgress: CGFloat = .zero

    /// Other Properties
    @State private var isKeyboardShowing: Bool = false

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
        .sheet(isPresented: $showSheet, onDismiss: {
            /// Reseting View properites
            sheetHeight = .zero
            sheetFirstPageHeight = .zero
            sheetSecondPageHeight = .zero
            sheetScrollProgress = .zero
        }, content: {
            /// Sheet View
            GeometryReader(content: { geometry in
                let size = geometry.size
                ScrollViewReader(content: { proxy in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 0) {
                            onBoardingView(size)
                                .id("First Page")

                            loginView(size)
                                .id("Second Page")
                        }
                        /// required for paging scrollview
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    /// Disabling scroll view when keyboard is active
                    .scrollDisabled(isKeyboardShowing)
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
                                .frame(width: 120 + (sheetScrollProgress * (hasAccount ? -10 : 50)))
                                .overlay(content: {
                                    /// Next page text
                                    HStack(spacing: 8) {
                                        Text(hasAccount ? "Login" : "Get Started")

                                        Image(systemName: "arrow.right")
                                    }
                                    .fontWeight(.semibold)
                                    .opacity(sheetScrollProgress)
                                })
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(
                                    .linearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), in: .capsule
                                )
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
            .onReceive(NotificationCenter.default.publisher(for:
                UIResponder.keyboardWillShowNotification), perform: { _ in
                isKeyboardShowing = true
            })
            .onReceive(NotificationCenter.default.publisher(for:
                UIResponder.keyboardWillHideNotification), perform: { _ in
                isKeyboardShowing = false
            })
        })
    }

    /// First View for Sheet
    @ViewBuilder
    func onBoardingView(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12, content: {
            Text("Know Everything\nabout the Abyss")
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
    // swiftlint:disable:next function_body_length
    func loginView(_ size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Descend to the Abyss")
                .minimumScaleFactor(0.9)
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
        .overlay(alignment: .bottomTrailing, content: {
            VStack(spacing: 15) {
                Group {
                    if hasAccount {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(.gray)

                            Button("Login") {
                                withAnimation(.snappy) {
                                    hasAccount.toggle()
                                }
                            }
                        }
                        .transition(.push(from: .bottom))
                    } else {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.gray)

                            Button("Create an account") {
                                withAnimation(.snappy) {
                                    hasAccount.toggle()
                                }
                            }
                        }
                        .transition(.push(from: .bottom))
                    }
                }
                .font(.callout)
                .textScale(.secondary)
                .padding(.bottom, hasAccount ? 0 : 15)

                if !hasAccount {
                    Text("""
                    By signing up, you're agreeing to our
                    **[Terms & Condition](https://apple.com)** and **[Privacy Policy](https://apple.com)***
                    """)
                    .font(.caption)
                    /// Markup content will be red
                    .tint(.red)
                    /// Other text be gray
                    .foregroundStyle(.gray)
                    .transition(.offset(y: 100))
                }
                // testing
//                Text("\(sheetScrollProgress)")
            }
            .padding(.bottom, 15)
            .padding(.horizontal, 20)
            .multilineTextAlignment(.center)
            .frame(width: size.width)
        })
        .frame(width: size.width)
        /// Finding the view's height
        .heightChangePreference { height in
            sheetSecondPageHeight = height
            /// Just in case  if the Height of the view has changed
            ///  Currently  withAnimation not animate the sheet height in SwiftUI (xcode 15)
            let diff = sheetSecondPageHeight - sheetFirstPageHeight
            sheetHeight = sheetFirstPageHeight + (diff * sheetScrollProgress)
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
