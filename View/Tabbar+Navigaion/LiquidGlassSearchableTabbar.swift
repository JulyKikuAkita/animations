//
//  LiquidGlassSearchableTabbar.swift
//  animation
//
//  Created on 6/21/25.

import SwiftUI

#if canImport(FoundationModels)

    struct LiquidGlassSearchableTabbarDemo: View {
        var body: some View {
            LiquidGlassSearchableTabbar()
        }
    }

    struct LiquidGlassSearchableTabbar: View {
        @State private var searchText: String = ""
        @State private var expandMiniPlayer: Bool = false
        @Namespace private var animation

        var body: some View {
            Group {
                if #available(iOS 26, *) {
                    NativeTabView(searchText: $searchText)
                        .tabBarMinimizeBehavior(.onScrollDown)
                        .tabViewBottomAccessory {
                            miniPlayerView()
                                .matchedTransitionSource(
                                    id: "MINIPLAYER",
                                    in: animation
                                )
                                .onTapGesture {
                                    expandMiniPlayer.toggle()
                                }
                        }
                } else {
                    NativeTabView(searchText: $searchText)
                        .overlay(alignment: .bottom) {
                            miniPlayerView()
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: .rect(cornerRadius: 15, style: .continuous))
                                .matchedTransitionSource(
                                    id: "MINIPLAYER",
                                    in: animation
                                )
                                .onTapGesture {
                                    expandMiniPlayer.toggle()
                                }
                                .offset(y: -60)
                                .padding(.horizontal, 15)
                        }
                        .ignoresSafeArea(.keyboard, edges: .all)
                }
            }
            .fullScreenCover(isPresented: $expandMiniPlayer) {
                ScrollView {}
                    .safeAreaInset(edge: .top, spacing: 0) {
                        VStack(spacing: 10) {
                            /// drag indicator
                            Capsule()
                                .fill(.primary.secondary)
                                .frame(width: 35, height: 3)

                            HStack(spacing: 0) {
                                playerInfo(.init(width: 80, height: 80))

                                Spacer(minLength: 0)

                                /// Expand actions
                                Group {
                                    Button("", systemImage: "star.circle.fill") {}
                                    Button("", systemImage: "ellipsis.circle.fill") {}
                                }
                                .font(.title)
                                .foregroundStyle(Color.primary, Color.primary.opacity(0.1))
                            }
                            .padding(.horizontal, 15)
                        }
                        .navigationTransition(.zoom(sourceID: "MINIPLAYER", in: animation))
                    }
                    /// avoid transparency in animation
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.background)
            }
        }

        func playerInfo(_ size: CGSize) -> some View {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: size.height / 4)
                    .fill(.blue.gradient)
                    .frame(width: size.width, height: size.height)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Dummy title")
                        .font(.callout)

                    Text("Some dummy subtitle")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                .lineLimit(1)
            }
        }

        func miniPlayerView() -> some View {
            HStack(spacing: 15) {
                playerInfo(.init(width: 30, height: 30))

                Spacer(minLength: 0)

                Button {} label: {
                    Image(systemName: "play.fill")
                        .contentShape(.rect)
                }
                .padding(.trailing, 10)

                Button {} label: {
                    Image(systemName: "forward.fill")
                        .contentShape(.rect)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 15)
        }
    }

    #Preview {
        LiquidGlassSearchableTabbarDemo()
    }

    /// To achive floating bar effect in iOS 18 (without tabViewBottomAccessory API)
    /// we use a overlay on top of tapbar, but the overlay area is not tappable
    ///  we then apply bottom safe area padding to resolve it
    struct NativeTabView: View {
        @Binding var searchText: String
        var safeAreaBottomPadding: CGFloat = 0
        var body: some View {
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    NavigationStack {
                        List {}
                            .navigationTitle("Home")
                            .safeAreaPadding(.bottom, safeAreaBottomPadding)
                    }
                }

                Tab("New", systemImage: "square.grid.2x2.fill") {
                    NavigationStack {
                        List {}
                            .navigationTitle("What's New")
                            .safeAreaPadding(.bottom, safeAreaBottomPadding)
                    }
                }

                Tab("Radio", systemImage: "dot.radiowaves.left.and.right") {
                    NavigationStack {
                        List {}
                            .navigationTitle(Text("Radio"))
                            .safeAreaPadding(.bottom, safeAreaBottomPadding)
                    }
                }

                Tab("Library", systemImage: "square.stack.fill") {
                    NavigationStack {
                        List {}
                            .navigationTitle(Text("Library"))
                            .safeAreaPadding(.bottom, safeAreaBottomPadding)
                    }
                }

                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    NavigationStack {
                        List {}
                            .navigationTitle(Text("Search"))
                            .searchable(text: $searchText, placement: .toolbar, prompt: Text("Searching..."))
                    }
                }
            }
        }
    }
#endif
