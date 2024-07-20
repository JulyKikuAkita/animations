//
//  PhotoAppIOS18View.swift
//  demoApp

import SwiftUI

struct PhotoAppIOS18DemoView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            PhotoAppIOS18View(size:size, safeArea: safeArea)
                .ignoresSafeArea(.all, edges: .top)
        }
    }
}
struct PhotoAppIOS18View: View {
    var size: CGSize
    var safeArea: EdgeInsets
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                /// Photo Grid Scroll View
                PhotosScrollView(size:size, safeArea: safeArea)
                
                /// bottom half view
                OtherContents()
            }
        }
    }
}



#Preview {
    PhotoAppIOS18DemoView()
}
