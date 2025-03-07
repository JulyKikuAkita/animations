//
//  SnapshotDemoView.swift
//  animation
//
//  iOS 18 snapshot api - turn snapshot to an UIImage
//

import SwiftUI

struct SnapshotDemoView: View {
    @State private var trigger: Bool = false
    @State private var snapshot: UIImage?
    var body: some View {
        NavigationStack {
            List {
                ForEach(1...20, id: \.self) { index in
                        Text("List Cell \(index)")
                }
            }
            .navigationTitle("List View")
            toolbar {
                ToolbarItem {
                    Button("Take Snapshot") {
                        trigger.toggle()
                    }
                }
            }
        }
        .snapshot(trigger: trigger) {
            snapshot = $0
        }
        .overlay {
            if let snapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 15))
                    .padding(15)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        Rectangle()
                            .fill(.black.opacity(0.3))
                            .ignoresSafeArea()
                            .onTapGesture {
                                self.snapshot = nil
                            }
                    }
            }
        }
    }
}

struct SnapshotDemoImageView: View {
    @State private var trigger: Bool = false
    @State private var snapshot: UIImage?
    var body: some View {
        VStack(spacing: 25) {
            Button("Take Snapshot") {
                trigger.toggle()
            }

            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                Text("Dan Da Dan")
            }
            .foregroundStyle(.white)
            .padding()
            .background(.brown.gradient, in: .rect(cornerRadius: 15))
            .snapshot(trigger: trigger) {
                snapshot = $0
            }

            if let snapshot {
                Image(uiImage: snapshot)
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

#Preview {
    SnapshotDemoView()
}
