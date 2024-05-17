//
//  Graphs.swift
//  MyMint

import SwiftUI
import SwiftData
import Charts

// TODO: https://www.youtube.com/watch?v=qQ3NGkv8O8c&list=PLimqJDzPI-H88PbxlOtNPkD0n0n-q-__z&index=7
// 2:00
struct Graphs: View {
    @Query(animation: .snappy) private var transactions: [Transaction]
    @State private var chartGroups: [ChartGroup] = []

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    Graphs()
}
