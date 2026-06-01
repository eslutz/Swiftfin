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
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(L10n.previous)
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

    /// Shapes the system hover highlight as a rounded rectangle. Attach to a
    /// plain `Button` (or inside a `ButtonStyle`) so gaze/pointer highlighting
    /// matches the content's corner radius instead of defaulting to a capsule.
    func visionHoverEffect(cornerRadius: CGFloat) -> some View {
        buttonBorderShape(.roundedRectangle(radius: cornerRadius))
    }

    /// Centers a full-width action row inside a `List`/`Form` and clears its
    /// row chrome, so primary form buttons read as standalone actions on visionOS.
    func visionFormActionRow() -> some View {
        frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(.init(vertical: 8, horizontal: EdgeInsets.edgePadding))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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

// MARK: Vision collection fallbacks

// On visionOS the UIKit-backed `CollectionHStack` / `CollectionVGrid`
// components are unavailable, so native scroll views with lazy stacks are
// used instead. These wrap the shared scaffolding (insets, hidden scroll
// indicators, look-to-scroll, and paging prefetch) so each call site only
// supplies its data, layout, and item content.

struct VisionHorizontalScroll<Content: View>: View {

    private let scrollDisabled: Bool
    private let content: Content

    init(
        scrollDisabled: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.scrollDisabled = scrollDisabled
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: EdgeInsets.edgePadding / 2) {
                content
            }
            .padding(.horizontal, EdgeInsets.edgePadding)
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(scrollDisabled)
        .lookToScroll(.horizontal)
    }
}

struct VisionVGrid<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {

    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let columns: [GridItem]
    private let spacing: CGFloat
    private let padding: EdgeInsets
    private let contentMaxWidth: CGFloat?
    private let prefetchMargin: Int
    private let onReachedEnd: () -> Void
    private let content: (Data.Element) -> Content

    init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        columns: [GridItem],
        spacing: CGFloat,
        padding: EdgeInsets,
        contentMaxWidth: CGFloat? = nil,
        prefetchMargin: Int = 1,
        onReachedEnd: @escaping () -> Void,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.columns = columns
        self.spacing = spacing
        self.padding = padding
        self.contentMaxWidth = contentMaxWidth
        self.prefetchMargin = prefetchMargin
        self.onReachedEnd = onReachedEnd
        self.content = content
    }

    // The element whose appearance triggers loading the next page. Derived
    // from the tail so it is O(1) and avoids materializing an enumerated copy
    // of the whole collection on every render.
    private var prefetchTriggerID: ID? {
        data.suffix(Swift.max(prefetchMargin, 1)).first?[keyPath: id]
    }

    var body: some View {
        ScrollView {
            grid
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var grid: some View {
        let lazyGrid = LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(data, id: id) { item in
                content(item)
                    .onAppear {
                        if item[keyPath: id] == prefetchTriggerID {
                            onReachedEnd()
                        }
                    }
            }
        }
        .padding(padding)

        // Only the width-constrained (list) case needs the centering outer
        // frame; the unconstrained case fills naturally.
        if let contentMaxWidth {
            lazyGrid
                .frame(maxWidth: contentMaxWidth, alignment: .top)
                .frame(maxWidth: .infinity, alignment: .top)
        } else {
            lazyGrid
                .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
