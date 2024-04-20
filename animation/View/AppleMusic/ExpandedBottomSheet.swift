//
//  ExpandedBottomSheet.swift
//  animation

import SwiftUI

struct ExpandedBottomSheet: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    
    var body: some View {
        GeometryReader {
            
            let size = $0.size
            
            ///wip - video at 7:12
            /// https://www.youtube.com/watch?v=_KohThDWl5Y
            
        }
    }
}

#Preview {
    AppleMusicHomeView()
}
