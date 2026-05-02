//
//  BorderBeamTextFieldView.swift
//  animation
//
//  Created on 5/2/26.
import SwiftUI

struct BorderBeamTextFieldDemoView: View {
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 25) {
                TextField("Ask Anything...", text: .constant(""))
                    .padding(.top, 8)

                HStack(spacing: 20) {
                    Button {} label: {
                        Text("Name/Model Name")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.8))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(.fill, in: .capsule)
                    }

                    Spacer(minLength: 0)

                    Group {
                        Button {} label: {
                            Image(systemName: "plus")
                        }

                        Button {} label: {
                            Image(systemName: "cloud")
                        }

                        Button {} label: {
                            Image(systemName: "mic")
                        }

                        Button {} label: {
                            Image(systemName: "arrow.up")
                                .frame(width: 35, height: 35)
                                .background(.background, in: .circle)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(15)
            .background(.gray.opacity(0.1), in: .rounded())
        }
        .padding()
    }
}

#Preview {
    BorderBeamTextFieldDemoView()
}
