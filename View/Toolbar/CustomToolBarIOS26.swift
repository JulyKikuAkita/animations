//
//  CustomToolBarIOS26.swift
//  animation
//
//  Created on 2/11/26.
import SwiftUI

@available(iOS 26.0, *)
struct CustomToolBarIOS26DemoView: View {
    @State private var isPrimaryActionVisible: Bool = false
    @State private var title: String?
    @State private var subTitle: String?
    @State private var safeArea: EdgeInsets = .init()
    @State private var activeSubtitleIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 15) {
                    headerView()
                    dummyPopularEvents()

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Nearby Events")
                            .font(.title3)
                            .fontWeight(.semibold)

                        ForEach(sampleEvents.indices, id: \.self) { index in
                            eventsOnDay(index)
                        }
                    }
                    .padding(.bottom, 500)
                }
                .padding(15)
            }
            .customToolBarIOS26(
                isPrimaryActionVisible: isPrimaryActionVisible,
                title: title,
                subtitle: subTitle
            ) {
                Button("Back", systemImage: "chevron.left") {
                    isPrimaryActionVisible.toggle()
                }

            } trailing: {
                HStack(spacing: 15) {
                    Button("Search", systemImage: "magnifyingglass") {}
                    Button("Options", systemImage: "ellipsis") {}
                }
                .padding(.horizontal, 4)

            } primaryAction: {
                Button("Add", systemImage: "plus") {}
                    .buttonStyle(.glassProminent)
                    .tint(.orange)
            }
        }
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            safeArea = newValue
        }
        .onChange(of: activeSubtitleIndex) { _, newValue in
            if let newValue {
                subTitle = sampleEvents[newValue]
            } else {
                subTitle = nil
            }
        }
    }

    func headerView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Image(systemName: "swift")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .padding(15)
                .background(.orange.tertiary, in: .circle)
                .padding(.bottom, 5)

            Text("Swift/Taylor")
                .font(.title.bold())
                .onGeometryChange(for: Bool.self) {
                    let height = $0.size.height
                    let offset = $0.frame(in: .global).minY
                    return -offset > height
                } action: { newValue in
                    title = newValue ? "Swift/Taylor" : nil
                }

            Text("**125** Events  **15.6k** Subscribers")
                .font(.callout)

            Text(dummyDescription)
                .font(.callout)
                .lineLimit(5)

            Button("Subscribe") {}
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .frame(maxWidth: 140)
                .tint(.orange)
                .onGeometryChange(for: Bool.self) {
                    let height = $0.size.height
                    let offset = $0.frame(in: .global).minY
                    return -offset > height
                } action: { newValue in
                    isPrimaryActionVisible = newValue
                }
        }
        .padding(.bottom, 15)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.horizontal, -15)
        }
    }

    func dummyPopularEvents() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Popular Events")
                    .font(.title3)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }

            RoundedRectangle(cornerRadius: 30)
                .foregroundStyle(.gray.tertiary)
                .frame(height: 220)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.horizontal, -15)
        }
    }

    var sampleEvents: [String] {
        ["Tomorrow / Saturday", "Feb 14 / Sunday"]
    }

    func eventsOnDay(_ index: Int) -> some View {
        let title: String = sampleEvents[index]

        return VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .animation(.smooth(duration: 0.3, extraBounce: 0), body: { content in
                    content
                        .scaleEffect(activeSubtitleIndex == index ? 0.01 : 1, anchor: .top)
                })
                .onGeometryChange(for: Bool.self) {
                    let offset = $0.frame(in: .scrollView).minY
                    return -offset > 30
                } action: { newValue in
                    let previousIndex = index - 1
                    activeSubtitleIndex = newValue ? index : (previousIndex < 0 ? nil : previousIndex)
                }

            ForEach(1 ... 5, id: \.self) { _ in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 100, height: 100)

                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 250, height: 25)

                        RoundedRectangle(cornerRadius: 5)
                            .frame(height: 25)

                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 150, height: 25)
                    }
                }
                .foregroundStyle(.gray.tertiary)

                Divider()
            }
        }
    }
}

extension View {
    @ViewBuilder
    func customToolBarIOS26(
        isPrimaryActionVisible: Bool,
        title: String?,
        subtitle: String?,
        @ViewBuilder leading: @escaping () -> some View,
        @ViewBuilder trailing: @escaping () -> some View,
        @ViewBuilder primaryAction: @escaping () -> some View
    ) -> some View {
        modifier(
            CustomToolBarIOS26Modifier(
                isPrimaryActionVisible: isPrimaryActionVisible,
                title: title,
                subtitle: subtitle,
                leading: leading,
                trailing: trailing,
                primaryAction: primaryAction
            )
        )
    }
}

private struct CustomToolBarIOS26Modifier<Leading: View, Trailing: View, PrimaryAction: View>: ViewModifier {
    var isPrimaryActionVisible: Bool
    var title: String?
    var subtitle: String?
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var primaryAction: PrimaryAction

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leading
                }

                ToolbarItem(placement: .principal) {
                    Text(emptyStringToTakeAllSpaceTrick)
                        .overlay(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 2) {
                                if let title {
                                    Text(title)
                                        .foregroundStyle(.primary)
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .transition(.offset(y: 10).combined(with: AnyTransition(.blurReplace)))
                                }

                                if let subtitle {
                                    Text(subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                        .contentTransition(.numericText())
                                        .transition(.blurReplace)
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: title)
                            .animation(.easeInOut(duration: 0.25), value: subtitle)
                        }
                        .lineLimit(1)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    trailing
                }

                if isPrimaryActionVisible {
                    ToolbarItem(placement: .topBarTrailing) {
                        primaryAction
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .animation(.bouncy(duration: 0.3, extraBounce: 0), value: isPrimaryActionVisible)
    }

    /// without this, the title at toolbar align to either side based on available space
    ///  use overlay to display the title/subtitle to avoid shifting
    private var emptyStringToTakeAllSpaceTrick: String {
        String(repeating: " ", count: 50) /// 50 is good for phone, increase it for iPad
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        CustomToolBarIOS26DemoView()
    } else {
        // Fallback on earlier versions
    }
}
