//
//  ScrollablePageTabsColorView.swift
//  animation

import SwiftUI

struct ScrollablePageTabsColorDemoView: View {
    /// View Properties
    @State private var activeTab: Tab_iOS17 = .apps
    var offsetObserver = PageOffsetObserver()
    var body: some View {
        VStack(spacing: 15) {
            tabbar(.gray)
                .overlay {
                    if let collectionViewBounds = offsetObserver.collectionView?.bounds {
                        GeometryReader {
                            let width = $0.size.width
                            let tabCount = CGFloat(Tab_iOS17.allCases.count)
                            let capsuleWidth = width / tabCount
                            let progress = offsetObserver.offset / collectionViewBounds.width

                            Capsule()
                                .fill(.black)
                                .frame(width: capsuleWidth)
                                .offset(x: progress * capsuleWidth)

                            tabbar(.white, .semibold)
                                .mask(alignment: .leading) {
                                    Capsule()
                                        .frame(width: capsuleWidth)
                                        .offset(x: progress * capsuleWidth)
                                }
                        }
                    }
                }
//                .allowsHitTesting(false)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 5, y: 5)
                .shadow(color: .black.opacity(0.05), radius: 5, x: -5, y: -5)
                .padding([.horizontal, .top], 15)

            TabView(selection: $activeTab) {
                Tab_iOS17.apps.color
                    .tag(Tab_iOS17.apps)
                    .background {
                        /// ensure adding observer only once
                        if !offsetObserver.isObserving {
                            FindCollectionView {
                                offsetObserver.collectionView = $0
                                offsetObserver.observe()
                            }
                        }
                    }

                Tab_iOS17.photos.color
                    .tag(Tab_iOS17.photos)

                Tab_iOS17.profile.color
                    .tag(Tab_iOS17.profile)

                Tab_iOS17.chat.color
                    .tag(Tab_iOS17.chat)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .overlay {
                Text("\(offsetObserver.offset)")
            }
        }
    }

    func tabbar(_ tint: Color, _ weight: Font.Weight = .regular) -> some View {
        HStack(spacing: 0) {
            ForEach(Tab_iOS17.allCases, id: \.rawValue) { tab in
                Text(tab.title)
                    .font(.callout)
                    .fontWeight(weight)
                    .foregroundStyle(tint)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            activeTab = tab
                        }
                    }
            }
        }
    }
}

#Preview {
    ScrollablePageTabsColorDemoView()
}

// if iOS 16, just conform Observable Object
// SwiftUI page tabView is built on top of the UIKit's UICollectionView,
// which in turn provides the content offset so we need to extract the UIKit's
// UICollectionView from the SwiftUI Page Tab View
@Observable
class PageOffsetObserver: NSObject {
    var collectionView: UICollectionView?
    var offset: CGFloat = 0
    private(set) var isObserving: Bool = false

    deinit { // remove observer when class is deinit
        remove()
    }

    func observe() {
        guard !isObserving else { return }
        collectionView?.addObserver(self, forKeyPath: "contentOffset", context: nil)
        isObserving = true
    }

    func remove() {
        isObserving = false
        collectionView?.removeObserver(self, forKeyPath: "contentOffset")
    }

    /// benefit for using observer to monitor content offset change  than using delegate is to avoid
    /// customizing delegate might remove any of the SwiftUI default functionality
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change _: [NSKeyValueChangeKey: Any]?,
        context _: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentOffset" else { return }
        if let contentOffset = (object as? UICollectionView)?.contentOffset {
            offset = contentOffset.x
        }
    }
}

struct FindCollectionView: UIViewRepresentable {
    var result: (UICollectionView) -> Void
    func makeUIView(context _: Context) -> some UIView {
        let view = UIView()
        view.backgroundColor = .clear

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if let collectionView = view.collectionSuperView {
                result(collectionView)
            }
        }
        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}
}

private extension UIView {
    /// Finding the collectionView by traversing the superView
    var collectionSuperView: UICollectionView? {
        if let collectionView = superview as? UICollectionView {
            return collectionView
        }
        return superview?.collectionSuperView
    }
}
