//
//  CustomPagingIndicatorView.swift
//  demoApp

import SwiftUI

struct CustomPagingIndicatorView: View {
    @Environment(SharedData.self) private var sharedData
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id:\.self) { index in
                    Circle()
                    .opacity(index == 1 ? 0: 1)
                    .overlay {
                        if index == 1 {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 10))
                        }
                    }
                    .frame(width: 7, height: 7)
                    .foregroundStyle(sharedData.activePage == index ? Color.primary : .gray)
            }
        }
    }
}

#Preview {
    PhotoAppIOS18DemoView()
}
