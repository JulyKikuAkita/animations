//
//  iOS26View+Modifier+Extension.swift
//  animation
//
//  Created on 12/15/25.
// Created an effect as Apple Store that
// Whenever the scroll offset exceeds the trigger offset, the normal toolbar items fade out
// and the `after` content toolbar type becomes visible
//

import SwiftUI

extension View {
    func appStoreStyleToolBar(triggerOffset: CGFloat,
                              @ViewBuilder beforeTrailingContent: @escaping () -> some View,
                              @ViewBuilder afterTrailingContent: @escaping () -> some View,
                              @ViewBuilder beforeCenterContent: @escaping () -> some View,
                              @ViewBuilder afterCenterContent: @escaping () -> some View,
                              onStatusChanged: @escaping (_ isChanged: Bool) -> Void = { _ in }) -> some View
    {
        navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .modifier(
                AppStoreStyleToolBarHelper(
                    triggerOffset: triggerOffset,
                    beforeTrailingContent: beforeTrailingContent,
                    afterTrailingContent: afterTrailingContent,
                    beforeCenterContent: beforeCenterContent,
                    afterCenterContent: afterCenterContent,
                    onStatusChanged: onStatusChanged
                )
            )
    }
}

private struct AppStoreStyleToolBarHelper<T1: View,
    T2: View,
    C1: View,
    C2: View>: ViewModifier
{
    var triggerOffset: CGFloat
    @ViewBuilder var beforeTrailingContent: T1
    @ViewBuilder var afterTrailingContent: T2
    @ViewBuilder var beforeCenterContent: C1
    @ViewBuilder var afterCenterContent: C2
    var onStatusChanged: (Bool) -> Void = { _ in }
    /// View Properties
    @State private var isChanged: Bool = false
    func body(content: Content) -> some View {
        content
            /// use onScrollGeometryChange to check if meets `triggerOffset` threshold
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                let progress = max(min(newValue / triggerOffset, 1), 0)
                withAnimation(.easeInOut(duration: 0.25)) {
                    isChanged = progress > 0.99 /// adjusted as needed
                }
                onStatusChanged(isChanged)
            }
            .toolbar {
                /// Trailing content
                ToolbarItem(placement: .topBarTrailing) {
                    ZStack(alignment: .trailing) {
                        beforeTrailingContent
                            .hideWitScale(isChanged)

                        afterTrailingContent
                            .hideWitOffset(!isChanged)
                    }
                }
                .backportedSharedVisibility(.hidden)

                /// Center content
                ToolbarItem(placement: .title) {
                    ZStack(alignment: .center) {
                        beforeCenterContent
                            .hideWitScale(isChanged)

                        afterCenterContent
                            .hideWitOffset(!isChanged)
                    }
                    /// restrict tittle bar content height limit
                    .frame(maxHeight: 35)
                }
                .backportedSharedVisibility(.hidden)
            }
    }
}

/// helper to remove liquidGlass background (it's default for toolbar item in iOS26+)
private extension ToolbarItem {
    @ToolbarContentBuilder
    func backportedSharedVisibility(_ visibility: Visibility) -> some ToolbarContent {
        if #available(iOS 26, *) {
            self
                .sharedBackgroundVisibility(visibility)
        } else {
            self
        }
    }
}
