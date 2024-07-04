//
//  TabbarOverSheetView.swift
//  animation
//  SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15

// 3:54 https://www.youtube.com/watch?v=8Ys83qvnDvE&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=37
import SwiftUI

struct TabbarOverSheetView: View {
    @Environment(WindowSharedModel.self) private var windowSharedModel
    var body: some View {
        @Bindable var bindableObject = windowSharedModel
        TabView(selection: $bindableObject.activeTab, content: {
            Text("Tab content 1").tabItem { Text("Text label 1") }.tag(1)
            Text("Tab content 3").tabItem { Text("Text label 2") }.tag(3)

        })
    }
}

#Preview {
    TabbarOverSheetView()
}
