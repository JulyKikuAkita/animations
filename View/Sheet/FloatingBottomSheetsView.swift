//
//  FloatingBottomSheetsView.swift
//  animation

import SwiftUI

struct FloatingBottomSheetsViewDemo: View {
    /// View Properties
    @State private var showStyle1: Bool = false
    @State private var showStyle2: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Show Style1") {
                    showStyle1.toggle()
                }
                
                
                Button("Show Style2") {
                    showStyle2.toggle()
                }
            }
            .navigationTitle("Floating Bottom Sheet")
        }
        .floatingBottomSheet(isPresented: $showStyle1) {
            FloatingBottomSheetsView(
                title: "Replace Existing Folder?",
                content: dummyDescription,
                image: .init(
                    content: "questionmark.folder.fill",
                    foreground: .white,
                    tint: .blue
                ),
                button1: .init(
                    content: "Replace",
                    foreground: .white,
                    tint: .blue
                ),
                button2: .init(
                    content: "Cancel",
                    foreground: Color.primary,
                    tint: Color.primary.opacity(0.08)
                )
            )
            .presentationDetents([.height(330)])
            /// demo the shadow area - by default sheet background has shadows even if set background to clear color
            /// this might be issue say as below example
            //.presentationBackgroundInteraction(.enabled(upThrough: .height(330)))
        }
        .floatingBottomSheet(isPresented: $showStyle2) {
            // need to define background color and shadow
            Text("Drag me up")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background.shadow(.drop(radius: 5)), in: .rect(cornerRadius: 25))
                .padding(.horizontal, 15)
                .padding(.top, 15)
            /// don't use .large, it will make the main view shrink, use fraction(0.999) instead
                .presentationDetents([.height(100), .height(330), .fraction(0.999)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(330)))
        }
    }
}

struct FloatingBottomSheetsView: View {
    var title: String
    var content: String
    var image: Config
    var button1: Config
    var button2: Config?
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: image.content)
                .font(.title)
                .foregroundStyle(image.foreground)
                .frame(width: 65, height: 65)
                .background(image.tint.gradient, in: .circle)
            
            Text(title)
                .font(.title3.bold())
            
            Text(content)
                .font(.callout)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(.gray)
            
            ButtonView(button1)
            
            if let button2 {
                ButtonView(button2)
            }
        }
        .padding([.horizontal, .bottom], 15)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .padding(.top, 30)
        }
        .shadow(color: .black.opacity(0.12), radius: 8)
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    func ButtonView(_ config: Config) -> some View {
        Button {
            
        } label: {
            Text(config.content)
                .fontWeight(.bold)
                .foregroundStyle(config.foreground)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(config.tint.gradient, in: .rect(cornerRadius: 10))
        }
    }
    
    struct Config {
        var content: String
        var foreground: Color
        var tint: Color
    }
}

#Preview {
    FloatingBottomSheetsViewDemo()
}

extension View {
    @ViewBuilder
    func floatingBottomSheet<Content: View>(isPresented: Binding<Bool>, onDismiss: @escaping () -> () = {}, @ViewBuilder content: @escaping () -> Content) -> some View {
        self
            .sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .presentationCornerRadius(0)
                    .presentationBackground(.clear)
                    .presentationDragIndicator(.hidden)
                    .background(sheetShadowRemover())
            }
    }
}


fileprivate struct sheetShadowRemover: UIViewRepresentable {
    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let uiSheetView = view.viewBeforeWindow {
                for view in uiSheetView.subviews {
                    /// clearing shadows
                    view.layer.shadowColor = UIColor.clear.cgColor
                }
            }
        }
        return view
    }
}

fileprivate extension UIView {
    var viewBeforeWindow: UIView? {
        if let superview, superview is UIWindow {
            return self
        }
        
        return superview?.viewBeforeWindow
    }
}
