//
//  ThemeDM.swift
//  animation
//
//  Created on 10/11/26.

import SwiftUI

public enum Theme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case systemDefault = "System"

    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .light:
            .orange
        case .dark:
            .purple
        case .systemDefault:
            scheme == .dark ? .purple : .orange
        }
    }

    func backgroundColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .light:
            .white
        case .dark:
            .brown
        case .systemDefault:
            if scheme == .dark {
                .gray.opacity(0.7)
            } else {
                .gray.opacity(0.1)
            }
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        case .systemDefault:
            nil
        }
    }

    var symbol: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .systemDefault: "circle.lefthalf.filled"
        }
    }

    var captionText: String {
        switch self {
        case .light: "Light appearance stays on, day and light."
        case .dark: "Dark appearance stays on, day and light."
        case .systemDefault: "Matches your iPhone settings, day and night."
        }
    }
}

extension Color {
    static var darkBottom: Color {
        Color("darkBottom")
    }

    static var darkTop: Color {
        Color("darkTop")
    }

    static var hillBottomDark: Color {
        Color("hillBottomDark")
    }

    static var hillBottomLight: Color {
        Color("hillBottomLight")
    }

    static var hillCenterDark: Color {
        Color("hillCenterDark")
    }

    static var hillCenterLight: Color {
        Color("hillCenterLight")
    }

    static var hillTopDark: Color {
        Color("hillTopDark")
    }

    static var hillTopLight: Color {
        Color("hillTopLight")
    }

    static var lightBottom: Color {
        Color("lightBottom")
    }

    static var lightTop: Color {
        Color("lightTop")
    }

    static var moon: Color {
        Color("moon")
    }
}
