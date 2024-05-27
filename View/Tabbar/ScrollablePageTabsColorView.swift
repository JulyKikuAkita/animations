//
//  ScrollablePageTabsColorView.swift
//  animation

import SwiftUI

struct ScrollablePageTabsColorDemoView: View {
    /// View Properties
    @State private var activeTab: Tab = .apps
    
    var body: some View {
        VStack(spacing: 15) {
            TabView(selection: $activeTab) {
                Tab.apps.color
                    .tag(Tab.apps)
                
                Tab.photos.color
                    .tag(Tab.photos)
                
                Tab.profile.color
                    .tag(Tab.profile)
                
                Tab.chat.color
                    .tag(Tab.chat)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
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
    
    func observe() {
        
    }
    
    func remove() {
        
    }
}

struct FindCollectionView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            // TODO: 2:37
            // https://www.youtube.com/watch?v=-ysC37TRgTg&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=108
        }
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
       
    }
}

fileprivate extension UIView {
    /// Finding the collectionView by traversing the superView
    var collectionSuperView: UICollectionView? {
        if let collectionView = superview as? UICollectionView {
            return collectionView
        }
        return superview?.collectionSuperView
    }
}
