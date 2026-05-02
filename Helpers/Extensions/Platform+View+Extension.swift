//
//  Platform+View+Extension.swift
//  animation
//
// Purpose: platform-conditional view composition (iOS/macOS/tvOS/watchOS/visionOS).
//
// What belongs here:
//   - The `.platform(_:content:)` modifier and its `PlatformType` enum.
//   - Any future helper that uses `#if os(...)` to branch on build target.
//
// What does NOT belong here:
//   - Runtime OS-version gating (iOS 17 vs 26 etc.) — that's View+Compat.swift.
//     Rule of thumb: `#if os(...)` → here; `if #available(...)` → Compat.
//
import SwiftUI

struct DemoView: View {
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
    DemoView()
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
