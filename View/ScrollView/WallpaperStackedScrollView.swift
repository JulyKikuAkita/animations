//
//  WallpaperStackedScrollView.swift
//  animation

import SwiftUI

@available(iOS 26.0, *)
struct WallpaperStackedScrollDemo: View {
    @State private var showWallpapers: Bool = false
    @Namespace private var animation
    var body: some View {
        VStack {
            Text("ADD NEW")
                .fontWeight(.medium)

            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.fill.tertiary)
                    .aspectRatio(0.452, contentMode: .fit)
            }

            VStack {
                Text("7:77")
                    .font(.system(size: 90, weight: .medium, design: .rounded))
                    .padding(.top, 40)
                    .blendMode(.softLight)

                Spacer(minLength: 0)
            }

            Button {
                showWallpapers.toggle()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.medium)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.glass)
            .matchedTransitionSource(id: "VIEW", in: animation)
        }
        .padding(50)
        .fullScreenCover(isPresented: $showWallpapers) {
            WallpaperPackView()
                .navigationTransition(.zoom(sourceID: "VIEW", in: animation))
        }
    }
}

@available(iOS 26.0, *)
struct WallpaperPackView: View {
    @State private var toggle: Bool = false
    var body: some View {
        VStack {
            let pack = packs[1]
            WallpaperStackView(title: pack.title, description: pack.description, trigger: toggle) {
                ForEach(pack.imageSets, id: \.self) { wallpaper in
                    Rectangle()
                        .foregroundStyle(.clear)
                        .overlay {
                            Image(wallpaper)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                }
            } buttonView: {
                Button {
                    toggle.toggle()
                } label: {
                    Text("GET")
                }
                .fontWeight(.medium)
                .buttonStyle(.borderedProminent)
                .tint(.gray.opacity(0.35))
                .buttonSizing(.flexible)
                .frame(maxWidth: 80)
            }
        }
        .safeAreaPadding(15)
    }
}

@available(iOS 26.0, *)
#Preview {
    WallpaperStackedScrollDemo()
        .preferredColorScheme(.dark)
}

@available(iOS 26.0, *)
#Preview {
    WallpaperPackView()
        .preferredColorScheme(.dark)
}

struct WallpaperStackView<Content: View, ButtonView: View>: View {
    var title: String
    var description: String
    /// covert toggle
    var trigger: Bool = false
    var minimizeWallpaperSize: CGSize = .init(width: 81, height: 176)
    var expandedWallpaperSize: CGSize = .init(width: 111, height: 241)
    @ContentBuilder var content: Content
    @ContentBuilder var buttonView: ButtonView

    /// View Properties
    @State private var scaleUp: Bool = false
    @State private var expand: Bool = false
    @State private var remove: Bool = false
    @State private var contentExpandedHeight: CGFloat = 0
    @State private var isExpanded: Bool = false
    @State private var animationTask: DispatchWorkItem?

    var body: some View {
        let layout = scaleUp ? AnyLayout(VStackLayout(alignment: .leading, spacing: 15)) : AnyLayout(ZStackLayout(alignment: .leading))

        layout {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.title.bold())
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if scaleUp {
                        buttonView
                    }
                }

                /// Text effect
                Group {
                    if scaleUp {
                        Text(description)
                            .lineLimit(2)
                            .transition(.blurReplace)
                    } else {
                        Text(description)
                            .lineLimit(3)
                            .transition(.blurReplace)
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)

                if !scaleUp {
                    buttonView
                }
            }
            .padding(.leading, scaleUp ? 0 : minimizeWallpaperSize.width + 60)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 18) {
                    Group(subviews: content) { collection in
                        ForEach(collection.prefix(scaleUp ? collection.count : 3)) { subview in
                            let index = collection.firstIndex(where: { $0.id == subview.id }) ?? 0

                            subview
                                .frame(width: width, height: height)
                                .visualEffect { [scaleUp, expand] content, proxy in
                                    let minX = proxy.frame(in: .scrollView).minX
                                    return content
                                        .scaleEffect(
                                            scaleUp ? 1 : 1 - (CGFloat(index) * 0.1),
                                            anchor: .trailing
                                        )
                                        .offset(x: scaleUp ? 0 : CGFloat(index) * 10)
                                        .offset(x: expand ? 0 : -minX)
                                }
                                .zIndex(Double(-index))
                        }
                    }
                }
            }
            .frame(height: height)
            .allowsHitTesting(expand)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { newValue in
            if !remove {
                contentExpandedHeight = newValue
            }
        }
        .frame(minHeight: remove ? contentExpandedHeight : minimizeWallpaperSize.height)
        .onChange(of: trigger) { _, _ in
            isExpanded.toggle()
            if isExpanded {
                withAnimation(.interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: 0)) {
                    scaleUp = true
                }
            } else {
                /// Close
                withAnimation(.interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: 0)) {
                    scaleUp = false
                }
            }
        }
    }

    private var width: CGFloat {
        scaleUp ? expandedWallpaperSize.width : minimizeWallpaperSize.width
    }

    private var height: CGFloat {
        scaleUp ? expandedWallpaperSize.height : minimizeWallpaperSize.height
    }
}
