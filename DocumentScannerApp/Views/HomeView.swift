//
//  HomeView.swift
//  DocumentScannerApp

import SwiftUI
import SwiftData

struct HomeView: View {
    /// View Properties
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25, extraBounce: 0)) private var documents: [Document]
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2), spacing: 15) {
                    ForEach(documents) { document in
                        
                    }
                }
                .padding(15)
            }
            .navigationTitle("Document's")
            .safeAreaInset(edge: .bottom) {
                CreateButton()
            }
        }
    }
    
    @ViewBuilder
    private func CreateButton() -> some View {
        Button {
            
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "document.viewfinder.fill")
                    .font(.title3)
                
                Text("Scan Documents")
            }
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.purple.gradient, in: .capsule)
        }
        .hSpacing(.center)
        .padding(.vertical, 10)
    }
}
