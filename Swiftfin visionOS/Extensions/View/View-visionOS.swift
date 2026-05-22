//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    // MARK: No-op stubs

    /// - Important: This does nothing on visionOS.
    @ViewBuilder
    func detectOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    @ViewBuilder
    func focusSection() -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    @ViewBuilder
    func navigationBarOffset(_ scrollViewOffset: Binding<CGFloat>, start: CGFloat, end: CGFloat) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    @ViewBuilder
    func navigationBarDrawer(@ViewBuilder _ drawer: @escaping () -> some View) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    @ViewBuilder
    func prefersStatusBarHidden(_ hidden: Bool = true) -> some View {
        self
    }

    // MARK: Navigation modifiers

    func navigationBarFilterDrawer(
        viewModel: FilterViewModel,
        types: [ItemFilterType]
    ) -> some View {
        modifier(
            VisionNavigationBarFilterModifier(
                viewModel: viewModel,
                types: types
            )
        )
    }

    func navigationBarCloseButton(
        disabled: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    action()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .disabled(disabled)
            }
        }
    }

    func navigationBarMenuButton(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ViewBuilder
        _ items: @escaping () -> some View
    ) -> some View {
        modifier(
            VisionNavigationBarMenuModifier(
                isLoading: isLoading,
                isHidden: isHidden,
                items: items
            )
        )
    }

    func listRowCornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: Filter modifier

private struct VisionNavigationBarFilterModifier: ViewModifier {

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    let types: [ItemFilterType]

    func body(content: Content) -> some View {
        content.toolbar {
            if types.isNotEmpty {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu(L10n.filters, systemImage: "line.3.horizontal.decrease.circle") {
                        if viewModel.currentFilters.isNotEmpty {
                            Button(L10n.reset, role: .destructive) {
                                viewModel.reset(filterType: nil)
                            }
                        }

                        ForEach(types, id: \.self) { type in
                            Button {
                                router.route(
                                    to: .filter(
                                        type: type,
                                        viewModel: viewModel
                                    )
                                )
                            } label: {
                                Label(type.displayTitle, systemImage: type.systemImage)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: Menu modifier

private struct VisionNavigationBarMenuModifier<MenuItems: View>: ViewModifier {

    let isLoading: Bool
    let isHidden: Bool
    let items: () -> MenuItems

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isLoading {
                    ProgressView()
                }

                if !isHidden {
                    Menu(L10n.options, systemImage: "ellipsis.circle") {
                        items()
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
    }
}
