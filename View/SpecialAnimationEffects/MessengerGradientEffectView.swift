//
//  MessengerGradientEffectView.swift
//  animation

import SwiftUI

struct MessengerGradientEffectDemoView: View {
    var body: some View {
        NavigationStack {
            MessengerGradientEffectView()
                .navigationTitle("Messages")
        }
    }
}

struct MessengerGradientEffectView: View {
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(messages) { message in
                        MessageCardView(screenProxy: proxy, message: message)
                    }
                }
                .padding(15)
            }
        }
    }
}

struct MessageCardView: View {
    var screenProxy: GeometryProxy
    var message: Message
    var body: some View {
        Text(message.message)
            .padding(10)
            .foregroundStyle(message.isReply ? Color.primary : .white)
            .background {
                if message.isReply {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.gray.opacity(0.3))
                } else {
                    GeometryReader {
                        let actualSize = $0.size
                        let rect = $0.frame(in: .global)
                        let screenSize = screenProxy.size
                        let safeArea = screenProxy.safeAreaInsets

                        Rectangle()
                            .fill(.linearGradient(colors: [
                                .pink,
                                .pink.opacity(0.8),
                                .purple,
                                .purple.opacity(0.8),
                                .yellow,
                                .orange,
                                .brown,
                            ], startPoint: .top, endPoint: .bottom))
                            .mask(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(
                                        width: actualSize.width,
                                        height: actualSize.height
                                    )
                                    .offset(x: rect.minX, y: rect.minY)
                            }
                            .offset(x: -rect.minX, y: -rect.minY)
                            .frame(
                                width: screenSize.width,
                                height: screenSize.height + safeArea.top + safeArea.bottom
                            )
                    }
                }
            }
            .frame(
                maxWidth: 250,
                alignment: message.isReply ? .leading : .trailing
            )
            .frame(
                maxWidth: .infinity,
                alignment: message.isReply ? .leading : .trailing
            )
    }
}

#Preview {
    MessengerGradientEffectDemoView()
}
