//
//  ThemeSwitchView.swift
//  animation
import SwiftUI

struct ThemeSwitchDemoView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var changeTheme: Bool = false
    @AppStorage("user_theme") private var userTheme: Theme = .systemDefault

    var body: some View {
        NavigationStack {
            List{
                Section("Appearance") {
                    Button("Change Theme") {
                        changeTheme.toggle()
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(userTheme.colorScheme)
        .sheet(isPresented: $changeTheme, content: {
            ThemeSwitchView(scheme: scheme)
                .presentationDetents([.height(410)]) /// maxHeight is 410
                .presentationBackground(.clear)
        })
    }
}
struct ThemeSwitchView: View {
    // @Environment(\.colorScheme) private var scheme // didn't work in sheet
    var scheme: ColorScheme
    @AppStorage("user_theme") private var userTheme: Theme = .systemDefault
    /// Sliding effect
    @Namespace private var animation
    /// View Properties
    @State private var circleOffset: CGSize = .zero
    init(
        scheme: ColorScheme
    ) {
        self.scheme = scheme
        let isDark = scheme == .dark
        self._circleOffset = .init(
            initialValue: CGSize(width: isDark ? 30 : 150, 
                                 height: isDark ? -25: -150)
        )
    }
    var body: some View {
        VStack(spacing: 15) {
            Circle()
                .fill(userTheme.color(scheme).gradient)
                .frame(width: 150, height: 150)
                .mask {
                    /// Inverting mask
                    Rectangle()
                        .overlay {
                            Circle()
                                .offset(circleOffset) // (x: 150, y: -150)
                                .blendMode(.destinationOut)
                        }
                }
            
            Text("Choose a Style")
                .font(.title2.bold())
                .padding(.top, 25)
//                .foregroundStyle(userTheme.color(scheme))
            
            Text("Pop or subtle. Day or night.\nCustomize your interface.")
                .multilineTextAlignment(.center)
//                .foregroundStyle(userTheme.color(scheme))
            
            /// Segment picker
            HStack(spacing: 0) {
                ForEach(Theme.allCases, id:\.rawValue) { theme in
                    Text(theme.rawValue)
                        .padding(.vertical, 15)
                        .frame(width: 100)
                        .background {
                            ZStack {
                                if userTheme == theme {
                                    Capsule()
                                        .fill(theme.backgroundColor(scheme))
                                        .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                }
                            }
                            .animation(.snappy, value: userTheme)
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            userTheme = theme
                        }
                }
            }
            .padding(3)
            .background(.primary.opacity(0.06), in: .capsule)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 410) /// maxHeight
        .background(userTheme.backgroundColor(scheme))
        .clipShape(.rect(cornerRadius: 30))
        .padding(.horizontal, 15)
        .environment(\.colorScheme, scheme)
        .onChange(of: scheme, initial: false) { _, newValue in
            let isDark = newValue == .dark
            withAnimation(.bouncy) {
                circleOffset =  CGSize(width: isDark ? 30 : 150,
                                       height: isDark ? -25: -150)
            }
        }
    }
}

#Preview {
    ThemeSwitchDemoView()
}

enum Theme: String, CaseIterable {
    case systemDefault = "Default"
    case light = "Light"
    case dark = "Dark"
    
    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .systemDefault:
            return scheme == .dark ? .purple : .orange
        case .light:
            return .orange
        case .dark:
            return .purple
        }
    }
    
    func backgroundColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .systemDefault:
            return scheme == .dark ? .gray.opacity(0.7) : .gray.opacity(0.1)
        case .light:
            return .white
        case .dark:
            return .brown
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .systemDefault:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
