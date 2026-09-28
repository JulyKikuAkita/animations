//
//  Safari27CollapsibleDemo.swift
//  animation
//
//  Created on 9/27/26.
  
import SwiftUI

@available(iOS 26.0, *)
struct Safari27CollapsibleDemo: View {
    @State private var safeArea: EdgeInsets = .init()
    @State private var text: String = ""
    @State private var isMinimized: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 2000)
                .overlay(alignment: .top) {
                    Button("Toggle") {
                        isMinimized.toggle()
                    }
                }
        }
        /// auto-dismiss keyboard when scroll
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CollapsibleBottomBar27Style(safeArea: safeArea, text: $text, isMinimized: $isMinimized) {
                SFBAction(symbol: "chevron.left") {
                    
                }
                
                SFBAction(symbol: "chevron.right") {
                    
                }
                
                SFBAction(symbol: "square.and.arrow.up") {
                    
                }
                
                SFBAction(symbol: "bookmark") {
                    
                }
                
                SFBAction(symbol: "square.on.square") {
                    
                }
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            safeArea = newValue
        }
    }
}

struct SFBAction: Identifiable {
    private(set) var id: String = UUID().uuidString
    var symbol: String
    var action: () -> Void
}

@resultBuilder
struct SFBActionBuilder {
    static func buildBlock(_ actions: SFBAction...) -> [SFBAction] {
        actions
    }
}

@available(iOS 26.0, *)
struct CollapsibleBottomBar27Style: View {
    var safeArea: EdgeInsets
    @Binding var text: String
    @Binding var isMinimized: Bool
    @Binding var progress: CGFloat
    @SFBActionBuilder var actions: [SFBAction]
    /// View Properties
    let padding: CGFloat = 18
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: isMinimized ? 0 : 10) {
            ZStack {
                if isMinimized {
                    Text(text.isEmpty ? "Search here" : text)
                        .font(isMinimized ? .caption : .body)
                        .foregroundStyle(text.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                } else {
                    Capsule()
                        .fill(.clear)
                }
            }
            .frame(height: isMinimized ? 35 : 45)

            HStack(spacing: 0) {
                ForEach(actions) { action in
                    actionView(action)
                }
            }
            .compositingGroup()
            .opacity(isMinimized ? 0 : 1)
            .blur(radius: isMinimized ? 10 : 0)
            .frame(
                width: isMinimized ? 0 : nil,
                height: isMinimized ? 0 : nil,
                alignment: .top
            )
            .padding(.horizontal, isMinimized ? 0 : -15)
        }
        .geometryGroup()
        .padding(isMinimized ? 0 : padding)
        .clipShape(.rect(cornerRadius: 30)) // match ConcentricRectangle
        .overlay {
            if isMinimized {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(.rect)
                    .onTapGesture {
                        isMinimized = false
                    }
                    .transition(.identity)
            }
        }
        .glassEffect(
            .regular.interactive(isMinimized),
            in: ConcentricRectangle(corners: .concentric(minimum: .fixed(30)),
                                             isUniform: true)
        )
        .animation(.iSpring().speed(1.5)) {
            $0.opacity(isFocused ? 0 : 1)
        }
        .overlay(alignment: isFocused ? .bottom : .top) {
            searchBar()
                .padding(isFocused || isMinimized ? 0 : padding)
                .opacity(isMinimized ? 0 : 1)
                .allowsHitTesting(!isMinimized)
        }
        .padding([.horizontal, .bottom], padding)
        .frame(minWidth: isMinimized ? 180 : nil)
        .animation(.iSpring(), value: isMinimized)
    }
    
    private func searchBar() -> some View {
        ZStack(alignment: .leading) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .opacity(isFocused ? 0 : 1)
            
            TextField("Search here", text: $text)
                .padding(.leading, isFocused ? 0 :30)
        }
        .padding(.horizontal, 15)
        .frame(height: isMinimized ? 35 : 45)
        .background {
            if colorScheme == .dark {
                Capsule()
                    .fill(.black)
            } else {
                Capsule()
                    .fill(.regularMaterial)
            }
        }
        .tint(Color.white)
        .environment(\.colorScheme, .dark)
        .padding(.trailing, isFocused ? 55 : 0)
        .background(alignment: .trailing) {
            Button {
                isFocused = false
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 20, height: 30)
            }
            .buttonStyle(.glass)
            .animation(.iSpring().speed(2)) {
                $0.opacity(isFocused ? 1 : 0)
            }
        }
        .focused($isFocused)
        /// adjust with keyboard
        .offset(y: isFocused ? -safeArea.bottom : 0)
        .animation(.iSpring(), value: isFocused)
    }
    
    private func actionView(_ item: SFBAction) -> some View {
        Button(action: item.action) {
            Image(systemName: item.symbol)
                .font(.title3)
                .frame(width: 45, height: 45)
                .foregroundStyle(.primary)
                .contentShape(.rect)
        }
        .frame(maxWidth: .infinity)
        
    }
}

@available(iOS 26.0, *)
#Preview {
    Safari27CollapsibleDemo()
}
