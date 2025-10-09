//
//  CustomTabbariOS26.swift
//  animation
import SwiftUI

@available(iOS 26.0, *)
struct CustomTabbariOS26DemoView: View {
    @State private var path: NavigationPath = .init() /// where at root view
    @State private var searchText: String = ""
    @FocusState private var isKeyboardActive: Bool
    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(1 ... 40, id: \.self) { index in
                    NavigationLink(value: "item") {
                        Text("Nanachi \(index)")
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationSubtitle("Last Updated: 2 minutes ago")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Options", systemImage: "ellipsis") {}
                }
            }
            ///  since safeAreaBar is attached to the entire navigation stack,
            ///  the max size of the bottom bar will alwyas be 50, so
            .safeAreaPadding(.bottom, 50)
            .navigationDestination(for: String.self) { value in
                Text("Details list")
                    .navigationTitle(value)
            }
        }
        .safeAreaBar(edge: .bottom, spacing: 0) {
            /// empty view is missing soft blur effect thus have "." instead of ""
            Text(".")
                .blendMode(.destinationOut)
                .frame(height: 50)
        }
        /// workaround for focusable issue in glass modifier
        .overlay(alignment: .bottom) {
            CustomBottomTapBar(path: $path, searchText: $searchText, isKeyboardActive: $isKeyboardActive) { isExpanded in
                Group {
                    ZStack {
                        Image(systemName: "line.3.horizontal.decrease")
                            .blurFade(!isExpanded)

                        Image(systemName: "trash")
                            .blurFade(isExpanded)
                    }

                    Group {
                        Image(systemName: "folder")

                        Image(systemName: "arrowshape.turn.up.forward.fill")
                    }
                    .blurFade(isExpanded)
                }
                .font(.title2)
            } mainAction: {
                Image(systemName: isKeyboardActive ? "xmark" : "square.and.pencil")
                    .font(.title2)
                    .contentTransition(.symbolEffect)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.circle)
                    .onTapGesture {
                        if isKeyboardActive {
                            isKeyboardActive = false
                        }
                    }
            }
        }
    }
}

@available(iOS 26.0, *)
struct CustomBottomTapBar<LeadingContent: View, MainAction: View>: View {
    /// View Properties
    @Binding var path: NavigationPath
    @Binding var searchText: String
    var isKeyboardActive: FocusState<Bool>.Binding
    @ViewBuilder var leadingContent: (_ isExpanded: Bool) -> LeadingContent
    @ViewBuilder var mainAction: MainAction
    @State private var bounce: CGFloat = .zero
    var body: some View {
        GlassEffectContainer(spacing: 10) { // this add morph effect (safe to remove if no morph)
            HStack(spacing: 10) {
                /// Hiding it when keyboard is expanded
                Circle()
                    .foregroundStyle(.clear)
                    .frame(width: 50, height: 50)
                    .overlay(alignment: .leading) {
                        let layout = isExpanded ? AnyLayout(HStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())

                        layout {
                            ForEach(subviews: leadingContent(isExpanded)) { subView in
                                subView
                                    .frame(width: 50, height: 50)
                            }
                        }
                        /// remove for glassContainer fix
                        .blurFade(!isKeyboardActive.wrappedValue)
                        /// remove for glassContainer fix -end
                        .modifier(ScaleModifier(bounce: bounce))
                    }
                    .zIndex(1000)
                    .transition(.blurReplace)
                    .blurFade(!isKeyboardActive.wrappedValue)

                /// Search bar
                GeometryReader { proxy in
                    let size = proxy.size
                    // scaling search bar wto hide behidethe leading content
                    // 50 is teh minimal width
                    let scale = 50 / size.width
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        TextField("Search", text: $searchText)
                            .submitLabel(.search)
                            .focused(isKeyboardActive)

                        Image(systemName: "mic.fill")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 15)
                    .frame(width: size.width, height: size.height)
                    .geometryGroup()
                    /// remove for glassContainer fix
                    .blurFade(!isExpanded)
                    .scaleEffect(isExpanded ? scale : 1, anchor: .topLeading)
                    /// remove for glassContainer fix -end
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .blurFade(!isExpanded)
                    .scaleEffect(isExpanded ? scale : 1, anchor: .leading)
                    .offset(x: isExpanded ? -50 : 0)
                }
                .frame(height: 50)
                /// 50 width + 10 spacing
                .padding(.leading, isKeyboardActive.wrappedValue ? -60 : 0)
                .disabled(isExpanded)

                mainAction
                    .frame(width: 50, height: 50)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, isKeyboardActive.wrappedValue ? 15 : 0)
            .animation(.bouncy, value: isExpanded)
            .animation(
                .smooth(duration: 0.3, extraBounce: 0),
                value: isKeyboardActive.wrappedValue
            )
            .onChange(of: isExpanded) { _, _ in
                withAnimation(.bouncy) {
                    bounce += 1
                }
            }
        }
    }

    var isExpanded: Bool {
        !path.isEmpty
    }
}

private extension View {
    @ViewBuilder
    func optionalGeometryGroup() -> some View {
        if #available(iOS 17, *) {
            self
                .geometryGroup()
        } else {
            self
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        CustomTabbariOS26DemoView()
    } else {
        // Fallback on earlier versions
    }
}

@available(iOS 26.0, *)
struct ScaleModifier: ViewModifier, Animatable {
    var bounce: CGFloat
    var animatableData: CGFloat {
        get { bounce }
        set { bounce = newValue }
    }

    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .blur(radius: loopProgress * 5)
            /// remove for glassContainer fix
            .offset(x: loopProgress * 15, y: loopProgress * 8)
            /// remove for glassContainer fix -end
            .glassEffect(.regular.interactive(), in: .capsule)
            .scaleEffect(1 + (loopProgress * 0.38), anchor: .center)
    }

    /// Returns a progress from 0 - 1 and back from 1 - 0 every time bounce is incremented!
    var loopProgress: CGFloat {
        let moddedBounce = bounce.truncatingRemainder(dividingBy: 1)
        let value = moddedBounce > 0.5 ? 1 - moddedBounce : moddedBounce
        return value * 2
    }
}
