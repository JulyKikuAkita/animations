//
//  ToolBarHeaderScrollEffectDemoView.swift
//  animation
//
//  Created on 12/15/25.

import SwiftUI

struct ToolBarHeaderScrollEffectDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("MockView") {
                    ToolBarHeaderScrollEffectDetailView()
                }
            }
            .navigationTitle("Apple Stoer")
        }
    }
}

struct ToolBarHeaderScrollEffectDetailView: View {
    @State private var isHeaderChanged: Bool = false
    @State private var isDownloaded: Bool = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(.sloth)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(.rect(cornerRadius: 25))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mockview")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("Graphic & Design")
                            .font(.callout)
                            .foregroundStyle(.gray)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)

                Image(.IMG_0204)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 850)
            }
        }
        .appStoreStyleToolBar(
            triggerOffset: 110,
            beforeTrailingContent: {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.medium)
                }
                .buttonStyle(ToolbarButtonStyleiOS26())
            },
            afterTrailingContent: {
                ZStack(alignment: .trailing) {
                    Button {
                        isDownloaded.toggle()
                    } label: {
                        Image(systemName: "icloud.and.arrow.down")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(ToolbarButtonStyleiOS26())
                    .opacity(isDownloaded ? 0 : 1)

                    Button {
                        isDownloaded.toggle()
                    } label: {
                        Text("Open")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .fixedSize()
                            .frame(width: isDownloaded ? nil : 0)
                    }
                    .buttonStyle(ToolbarButtonStyleiOS26(isTinted: true))
                    .opacity(isDownloaded ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.15), value: isDownloaded)
            },
            beforeCenterContent: {},
            afterCenterContent: {
                Image(.sloth)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .clipShape(.rect(cornerRadius: 10))

            }, onStatusChanged: { isChanged in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isHeaderChanged = isChanged
                }
            }
        )
    }
}

#Preview {
    ToolBarHeaderScrollEffectDemoView()
}
