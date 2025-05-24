//
//  MorphCustomMenuDemoView.swift
//  animation
//
//  iMessage morph menu effect
// use visual effect modifier for expand menu button animation
// also scaling and blur on the menu items
import SwiftUI

struct MorphCustomMenuDemoView: View {
    @State private var config: MenuConfig = .init(symbolImage: "plus")
    var body: some View {
        CustomMorphMeunView(config: $config) {
            NavigationStack {
                ScrollView(.vertical) {
                    ForEach(0 ..< 100, id: \.self) { _ in
                        Capsule()
                            .fill(.indigo.gradient)
                            .opacity(0.55)
                            .frame(height: 22)
                            .padding(12)
                    }
                }
                .navigationTitle(Text("Messages"))
                .safeAreaInset(edge: .bottom) {
                    bottomBar()
                }
            }
        } actions: {
            MenuAction(symbolImage: "camera", text: "Cameta")
            MenuAction(symbolImage: "photo.on.rectangle.angled", text: "Photos")
            MenuAction(symbolImage: "face.smiling", text: "Genmoji")
            MenuAction(symbolImage: "waveform", text: "Audio")
            MenuAction(symbolImage: "apple.logo", text: "Apple Store")
            MenuAction(symbolImage: "video.badge.waveform", text: "Facetime")
            MenuAction(symbolImage: "rectangle.and.text.magnifyingglass", text: "#Images")
            MenuAction(symbolImage: "suit.heart", text: "Digital Touch")
            MenuAction(symbolImage: "location", text: "Location")
            MenuAction(symbolImage: "music.note", text: "Music")
        }
    }

    func bottomBar() -> some View {
        HStack(spacing: 12) {
            MenuSourceBotton(config: $config) {
                Image(systemName: "plus")
                    .font(.title3)
                    .frame(width: 35, height: 35)
                    .background {
                        Circle()
                            .fill(.gray.opacity(0.35))
                            .background(.background, in: .circle)
                    }
            } onTap: {
                /// dismiss keyboard
            }

            TextField("Text Message", text: .constant(""))
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background {
                    Capsule()
                        .stroke(.gray.opacity(0.3), lineWidth: 1.5)
                }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }
}

/// a wrapper to show menu view on top of the base view
struct CustomMorphMeunView<Content: View>: View {
    @Binding var config: MenuConfig
    @ViewBuilder var content: Content
    @MenuActionBuilder var actions: [MenuAction]
    /// View Properties
    @State private var animateContent: Bool = false
    @State private var animateLabels: Bool = false
    /// resetting scroll position when menu closed
    @State private var activeActionID: String?
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                /// Blur overlay
                Rectangle()
                    .fill(.bar)
                    .ignoresSafeArea()
                    .opacity(animateContent ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .overlay {
                if animateContent {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .contentShape(.rect)
                        /// instead of using animation callback, use ondisappear to get notified when animation completes
                        .onDisappear {
                            config.hideSourceView = false
                            activeActionID = actions.first?.id
                        }
                }
            }
            .overlay {
                GeometryReader {
                    menuScrollView($0)

                    if config.hideSourceView {
                        config.sourceView
                            .scaleEffect(animateContent ? 15 : 1, anchor: .bottom)
                            .offset(x: config.sourceLocation.minX, y: config.sourceLocation.minY)
                            .opacity(animateContent ? 0.25 : 1)
                            .blur(radius: animateContent ? 130 : 0)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                }
                .opacity(config.hideSourceView ? 1 : 0)
            }
            .onChange(of: config.showMenu) { _, newValue in
                if newValue {
                    config.hideSourceView = true
                }
                withAnimation(.smooth(duration: 0.45, extraBounce: 0)) {
                    animateContent = newValue
                }

                withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                    animateLabels = newValue
                }
            }
    }

    func menuScrollView(_ proxy: GeometryProxy) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(actions) {
                    menuActionView($0)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity, alignment: .leading)
            /// show background tap to dismiss the menu view
            .background {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: proxy.size.width,
                           height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom)
                    .contentShape(.rect)
                    .onTapGesture {
                        guard config.showMenu else { return }
                        config.showMenu = false
                    }
                    /// sticking to the top
                    .visualEffect { content, proxy in
                        content
                            .offset(
                                x: -proxy.frame(in: .global).minX,
                                y: -proxy.frame(in: .global).minY
                            )
                    }
            }
        }
        .safeAreaPadding(.vertical, 20)
        /// make the view start at the center (70: menuActionView frame height)
        .safeAreaPadding(.top, (proxy.size.height - 70) / 2)
        .scrollPosition(id: $activeActionID, anchor: .top)
        .scrollIndicators(.hidden)
        .allowsHitTesting(config.showMenu)
    }

    @ViewBuilder
    func menuActionView(_ action: MenuAction) -> some View {
        let sourceLocation = config.sourceLocation

        HStack(spacing: 20) {
            Image(systemName: action.symbolImage)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(.background)
                        .shadow(radius: 1.5)
                }
                .scaleEffect(animateContent ? 1 : 0.6)
                .opacity(animateContent ? 1 : 0)
                .blur(radius: animateContent ? 0 : 4)

            Text(action.text)
                .font(.system(size: 19))
                .fontWeight(.medium)
                .lineLimit(1)
                .opacity(animateLabels ? 1 : 0)
                .blur(radius: animateLabels ? 0 : 4)
        }
        .visualEffect { [animateContent] content, proxy in
            content
                /// making the icon squeezed at the source button location
                .offset(
                    x: animateContent ? 0 : sourceLocation.minX - proxy.frame(in: .global).minX,
                    y: animateContent ? 0 : sourceLocation.minY - proxy.frame(in: .global).minY
                )
        }
        .frame(height: 70)
        .contentShape(.rect)
        .onTapGesture {
            action.action()
        }
    }
}

struct MenuSourceBotton<Content: View>: View {
    @Binding var config: MenuConfig
    @ViewBuilder var content: Content
    var onTap: () -> Void
    var body: some View {
        content
            .contentShape(.rect)
            .onTapGesture {
                config.sourceView = .init(content)
                config.showMenu.toggle()
            }
            /// Saving source view
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                config.sourceLocation = newValue
            }
            .opacity(config.hideSourceView ? 0.1 : 1)
    }
}

#Preview {
    MorphCustomMenuDemoView()
}

struct MenuConfig {
    var symbolImage: String
    var sourceLocation: CGRect = .zero
    var showMenu: Bool = false
    /// storing source view(lables) for scaling effect
    var sourceView: AnyView = .init(EmptyView())
    var hideSourceView: Bool = false
}

struct MenuAction: Identifiable {
    private(set) var id: String = UUID().uuidString
    var symbolImage: String
    var text: String
    var action: () -> Void = {}
}

/// helper to build nested views (view build is also result builder)
@resultBuilder
struct MenuActionBuilder {
    static func buildBlock(_ components: MenuAction...) -> [MenuAction] {
        components.compactMap(\.self)
    }
}
