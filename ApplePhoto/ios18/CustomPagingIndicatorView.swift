//
//  CustomPagingIndicatorView.swift
//  demoApp

import SwiftUI

struct CustomPagingIndicatorView: View {
    var onClose: () -> ()
    @Environment(SharedData.self) private var sharedData
    @Namespace private var animation
    var body: some View {
        let progress = sharedData.progress
        
        HStack(spacing: 8) {
            ForEach(1...4, id:\.self) { index in /// demo has fix 4 pages
                    Circle()
                        .opacity(index == 1 ? 0: 1)
                        .overlay {
                            if index == 1 { /// show grid symbol for first page, aka photo grid view
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 10))
                            }
                        }
                        .frame(width: 7, height: 7)
                        .foregroundStyle(sharedData.activePage == index ? Color.primary : .gray)
            }
        }
        .blur(radius: progress * 5)
        .opacity(1.0 - (progress * 4))
        .overlay(alignment: .center) {
            CustomButtonBar()
                .fixedSize()
                .blur(radius: (1 - progress) * 5)
                .opacity(progress)
        }
        .offset(y: -30 - (30 * progress))
    }
    
    @ViewBuilder
    func CustomButtonBar() -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(["Years", "Month", "All"], id: \.self) { category in
                    Button {
                        withAnimation(.snappy) {
                            sharedData.selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 6)
                            .background {
                                if sharedData.selectedCategory == category {
                                    Capsule()
                                        .fill(.gray.opacity(0.15))
                                        .matchedGeometryEffect(
                                            id: "ACTIVETAB",
                                            in: animation
                                        )
                                }
                            }
                    }
                }
            }
            .background(.ultraThinMaterial, in: .capsule)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .frame(width: 35, height: 35)
                    .background(.ultraThinMaterial, in: .capsule)

            }
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    PhotoAppIOS18DemoView()
}
