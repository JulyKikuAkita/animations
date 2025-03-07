//
//  DropDownView.swift
//  animation

import SwiftUI

struct DropDownView: View {
    /// Customizing  properties
    var hint: String
    var options: [String]
    var anchor: Anchor = .bottom
    var maxWidth: CGFloat = 180
    var cornerRadius: CGFloat = 15
    @Binding var selection: String?
    /// View  properties
    @State private var showOptions: Bool = false
    /// Environment scheme
    @Environment(\.colorScheme) private var scheme
    /// use scene storage to assign zIndex to selected dropdown
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var zIndex: Double = 1000.0
    var body: some View {
        GeometryReader {
            let size = $0.size

            VStack(spacing: 0) {
                if showOptions && anchor == .top{
                    OptionsView()
                }

                HStack(spacing: 0) {
                    Text(selection ?? hint)
                        .foregroundStyle(selection == nil ? .gray : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        /// rotating icon
                        .rotationEffect(.init(degrees: showOptions ? -180 : 0))
                }
                .padding(.horizontal, 15)
                .frame(width: size.width, height: size.height)
                .background(scheme == .dark ? .black : .white)
                .contentShape(.rect)
                .onTapGesture {
                    index += 1 /// scene storage increase 1
                    zIndex = index /// the tapped dropdown increased 1 and has a higher zIndex than rest of dropdowns
                    withAnimation(.snappy) {
                        showOptions.toggle()
                    }
                }
                .zIndex(10)

                if showOptions && anchor == .bottom{
                    OptionsView()
                }
            }
            .clipped()
            /// clips all interaction within it's bound
            .contentShape(.rect)
            .background((scheme == .dark ? Color.black : Color.white)
                .shadow(.drop(color: .primary.opacity(0.15), radius: 4)), in: .rect(cornerRadius: cornerRadius))
            .frame(height: size.height, alignment: anchor == .top ? .bottom : .top)
        }
        .frame(width: maxWidth, height: 50)
        .zIndex(zIndex) /// if just assign number to zindex for all dropdown, multiple dropdowns still overlap
    }

    /// Options View
    @ViewBuilder
    func OptionsView() -> some View {
        VStack(spacing: 10) {
            ForEach(options, id:\.self) { option in
                HStack(spacing: 0) {
                    Text(option)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "checkmark")
                        .font(.caption)
                        .opacity(selection == option ? 1: 0)
                }
                .foregroundStyle(selection == option ? Color.primary : Color.gray)
                .animation(.none, value: selection)
                .frame(height: 40)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selection = option
                        /// closing drop down view
                        showOptions = false
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        /// adding transition
        .transition(.move(edge: anchor == .top ? .bottom : .top))
    }

    /// Drop down direction
    enum Anchor {
        case top
        case bottom
    }
}

#Preview {
    ContentView()
}
