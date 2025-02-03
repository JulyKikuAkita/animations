//
//  View+Alert.swift
//  Alert

import SwiftUI

extension View {
    @ViewBuilder
    func alert<Content: View, Background: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder background:  @escaping () -> Background
    ) -> some View {
        self
            .modifier(
                CustomAlertIOS18APIModifier(isPresented: isPresented, alertContent: content, background: background)
            )
    }
}

fileprivate struct CustomAlertIOS18APIModifier<AlertContent: View, Background: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var alertContent: () -> AlertContent
    @ViewBuilder var background: () -> Background
    /// View Properties
    @State private var showFullscreenCover: Bool = false
    @State private var animatedValue: Bool = false
    @State private var allowsInteraction: Bool = false
    
    /// use full screen cover to show alert content on top of current content
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showFullscreenCover) {
                ZStack {
                    if animatedValue {
                        alertContent()
                            .allowsHitTesting(allowsInteraction)
                    }
                }
                .presentationBackground {
                    background()
                        .opacity(animatedValue ? 1 : 0)
                }
                .task {
                    try? await Task.sleep(for: .seconds(0.05))
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animatedValue = true
                    }
                    
                    /// enable view interaction after animation completes
                    try? await Task.sleep(for: .seconds(0.3))
                    allowsInteraction = true
                }
            }
            .onChange(of: isPresented) { oldValue, newValue in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                
                if newValue {
                    withTransaction(transaction) {
                        showFullscreenCover = true
                    }
                } else {
                    allowsInteraction = true
                    withAnimation(.easeInOut(duration: 0.3), completionCriteria: .removed) {
                        animatedValue = false
                    } completion: {
                        /// remove full screen cover without animation
                        withTransaction(transaction) {
                            showFullscreenCover = false
                        }
                    }
                }
            }
    }
}
