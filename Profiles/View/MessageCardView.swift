//
//  MessageCardView.swift
//  Profiles

import SwiftUI

struct MessageCardView: View {
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
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.blue.gradient)
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
    MessageCardView(message: messages.first!)
}
