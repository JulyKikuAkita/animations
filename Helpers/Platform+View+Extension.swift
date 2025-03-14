//
//  Platform+View+Extension.swift
//  animation
//
import SwiftUI

struct demoView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello World")
        }
        .platform(.iOS) { view in
            view.padding(25)
                .background(.red)
        }
        .platform(.macOS) { view in
            view.padding(10)
                .background(.blue)
        }
    }
}

#Preview {
    demoView()
}

enum PlatformType {
    case iOS
    case macOS
    case tvOS
    case watchOS
    case visionOS
}

extension View {
    @ViewBuilder
    func platform(_ type: PlatformType, @ViewBuilder content: (Self) -> some View) -> some View {
        switch type {
        case .iOS:
            #if os(iOS)
                content(self)
            #else
                self
            #endif

        case .macOS:
            #if os(macOS)
                content(self)
            #else
                self
            #endif
        case .tvOS:
            #if os(tvOS)
                content(self)
            #else
                self
            #endif
        case .watchOS:
            #if os(watchOS)
                content(self)
            #else
                self
            #endif
        case .visionOS:
            #if os(visionOS)
                content(self)
            #else
                self
            #endif
        }
    }
}
