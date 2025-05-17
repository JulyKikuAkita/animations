//
//  ThemeSwitcherView.swift
//  animation

import SwiftUI

struct ThemeSwitcherDemoView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(1 ... 40, id: \.self) {
                    Text("Chat History \($0)")
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPickerView.toggle()
                    } label: {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appScheme)
    }
}

#Preview {
    SchemeHostView {
        ThemeSwitcherDemoView()
    }
}
