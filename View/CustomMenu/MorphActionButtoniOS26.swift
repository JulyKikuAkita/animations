//
//  MorphActionButtoniOS26.swift
//  animation
//
//  Created on 6/24/25.

import SwiftUI

/// the morthButtonOverlay works in list, section, overlay
struct MorphActionButtonDemo: View {
    @State private var showExpandedContent: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section("Dummy Section") {
                    HStack {
                        morthButtonOverlay()
                        DummyTaskRow(isEmpty: true)
                    }
                }
            }
            .navigationTitle("Morphing Button")
        }
        .overlay(alignment: .bottomTrailing) {
            morthButtonOverlay()
        }
    }

    func morthButtonOverlay() -> some View {
        MorphingButton(
            backgroundColor: .black,
            showExpandedContent: $showExpandedContent
        ) {
            Image(systemName: "plus")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.background)
                .frame(width: 45, height: 45)
        } content: {
            DummyMenuView()
                .onTapGesture {
                    showExpandedContent.toggle()
                }
        } expandedContent: {
            dummyExpandedView()
        }
        .padding(.trailing, 20)
    }

    func dummyExpandedView() -> some View {
        VStack {
            HStack {
                Text("Expanded View")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    showExpandedContent = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                }
            }
            .padding(.leading, 10)

            Spacer()

            DummyRectangles(color: .indigo, count: 5)
        }
        .foregroundStyle(.background)
        .padding(15)
    }
}

struct MorphingButton<Label: View, Content: View, ExpandedContent: View>: View {
    var backgroundColor: Color
    @Binding var showExpandedContent: Bool
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content
    @ViewBuilder var expandedContent: ExpandedContent

    /// View Properties
    ///  use full screen instead of overlay so that the MorphingButton can apply to any view
    @State private var showFullScreenCover: Bool = false
    @State private var animateContent: Bool = false
    @State private var viewPosition: CGRect = .zero
    var body: some View {
        label
            .background(backgroundColor)
            .clipShape(.circle)
            .contentShape(.circle)
            .onGeometryChange(for: CGRect.self, of: {
                $0.frame(in: .global)
            }, action: { newValue in
                viewPosition = newValue
            })
            .opacity(showFullScreenCover ? 0 : 1)
            .onTapGesture {
                toggleFullScreenCover(false, status: true)
            }
            .fullScreenCover(isPresented: $showFullScreenCover) {
                ZStack(alignment: .topLeading) {
                    if animateContent {
                        ZStack(alignment: .top) {
                            if showExpandedContent {
                                expandedContent
                                    .transition(.blurReplace)
                            } else {
                                content
                                    .transition(.blurReplace)
                            }
                        }
                        .transition(.blurReplace)
                    } else {
                        label
                            .transition(.blurReplace)
                    }
                }
                /// animatino the group view (by default, each leaf view has its animation)
                .geometryGroup()
                .clipShape(.rect(cornerRadius: 30, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(backgroundColor)
                        .ignoresSafeArea()
                }
                .padding(
                    .horizontal,
                    animateContent && !showExpandedContent ? 15 : 0
                )
                .padding(.bottom, animateContent && !showExpandedContent ? 5 : 0)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: animateContent ? .bottom : .topLeading
                )
                .offset(
                    x: animateContent ? 0 : viewPosition.minX,
                    y: animateContent ? 0 : viewPosition.minY
                )
                .ignoresSafeArea(animateContent ? [] : .all)
                .background {
                    Rectangle()
                        .fill(.black.opacity(animateContent ? 0.05 : 0))
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0),
                                          completionCriteria: .removed)
                            {
                                animateContent = false
                            } completion: {
                                /// Removing sheet after a little delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    toggleFullScreenCover(false, status: false)
                                }
                            }
                        }
                }
                .task {
                    try? await Task.sleep(for: .seconds(0.05))
                    withAnimation(.interpolatingSpring(duration: 0.2, bounce: 0)) {
                        animateContent = true
                    }
                }
                .animation(
                    .interpolatingSpring(duration: 0.2, bounce: 0),
                    value: showExpandedContent
                )
            }
    }

    /// Transation: adds new view on top of parent view immediately without any animations
    /// the existing full cover sliding animation has been removed
    private func toggleFullScreenCover(_ withAnimation: Bool, status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = !withAnimation

        withTransaction(transaction) {
            showFullScreenCover = status
        }
    }
}

#Preview {
    MorphActionButtonDemo()
}
