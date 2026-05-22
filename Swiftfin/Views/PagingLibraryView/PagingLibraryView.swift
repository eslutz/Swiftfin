//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Nuke
import SwiftUI

#if os(visionOS)
private struct PagingCollectionLayout {

    let columns: [GridItem]
    let lineSpacing: CGFloat
    let padding: EdgeInsets
}
#else
import CollectionVGrid

private typealias PagingCollectionLayout = CollectionVGridLayout
#endif

// TODO: need to think about better design for views that may not support current library display type
//       - ex: channels/albums when in portrait/landscape
//       - just have the supported view embedded in a container view?
// TODO: could bottom (defaults + stored) `onChange` copies be cleaned up?
//       - more could be cleaned up if there was a "switcher" property wrapper that takes two
//         sources and a switch and holds the current expected value
//       - or if Defaults values were moved to StoredValues and each key would return/respond to
//         what values they should have
// TODO: when there are no filters sometimes navigation bar will be clear until popped back to

/*
 Note: Currently, it is a conscious decision to not have grid posters have subtitle content.
       This is due to episodes, which have their `S_E_` subtitles, and these can be alongside
       other items that don't have a subtitle which requires the entire library to implement
       subtitle content but that doesn't look appealing. Until a solution arrives grid posters
       will not have subtitle content.
       There should be a solution since there are contexts where subtitles are desirable and/or
       we can have subtitle content for other items.

 Note: For `rememberLayout` and `rememberSort`, there are quirks for observing changes while a
       library is open and the setting has been changed. For simplicity, do not enforce observing
       changes and doing proper updates since there is complexity with what "actual" settings
       should be applied.
 */

struct PagingLibraryView<Element: Poster>: View {

    private static var nextPagePrefetchThreshold: Int {
        5
    }

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters
    @Default(.Customization.Library.rememberLayout)
    private var rememberLayout

    @Default(.Customization.Library.displayType)
    private var defaultDisplayType: LibraryDisplayType
    @Default(.Customization.Library.listColumnCount)
    private var defaultListColumnCount: Int
    @Default(.Customization.Library.posterType)
    private var defaultPosterType: PosterDisplayType

    @Namespace
    private var namespace

    @Router
    private var router

    @State
    private var layout: PagingCollectionLayout
    @State
    private var safeArea: EdgeInsets = .zero

    @StoredValue
    private var displayType: LibraryDisplayType
    @StoredValue
    private var listColumnCount: Int
    @StoredValue
    private var posterType: PosterDisplayType

    #if !os(visionOS)
    @StateObject
    private var collectionVGridProxy: CollectionVGridProxy = .init()
    #endif
    @StateObject
    private var viewModel: PagingLibraryViewModel<Element>

    // MARK: init

    init(viewModel: PagingLibraryViewModel<Element>) {

        // have to set these properties manually to get proper initial layout

        self._displayType = StoredValue(.User.libraryDisplayType(parentID: viewModel.parent?.id))
        self._listColumnCount = StoredValue(.User.libraryListColumnCount(parentID: viewModel.parent?.id))
        self._posterType = StoredValue(.User.libraryPosterType(parentID: viewModel.parent?.id))

        self._viewModel = StateObject(wrappedValue: viewModel)

        let defaultDisplayType = Defaults[.Customization.Library.displayType]
        let defaultListColumnCount = Defaults[.Customization.Library.listColumnCount]
        let defaultPosterType = Defaults[.Customization.Library.posterType]

        let displayType = StoredValues[.User.libraryDisplayType(parentID: viewModel.parent?.id)]
        let listColumnCount = StoredValues[.User.libraryListColumnCount(parentID: viewModel.parent?.id)]
        let posterType = StoredValues[.User.libraryPosterType(parentID: viewModel.parent?.id)]

        let initialDisplayType = Defaults[.Customization.Library.rememberLayout] ? displayType : defaultDisplayType
        let initialListColumnCount = Defaults[.Customization.Library.rememberLayout] ? listColumnCount : defaultListColumnCount
        let initialPosterType = Defaults[.Customization.Library.rememberLayout] ? posterType : defaultPosterType

        if UIDevice.isPhone {
            layout = Self.phoneLayout(
                posterType: initialPosterType,
                viewType: initialDisplayType
            )
        } else {
            layout = Self.padLayout(
                posterType: initialPosterType,
                viewType: initialDisplayType,
                listColumnCount: initialListColumnCount
            )
        }
    }

    // MARK: action

    private func action(_ element: Element, in namespace: Namespace.ID) {
        switch element {
        case let element as BaseItemDto:
            select(item: element, in: namespace)
        case let element as BaseItemPerson:
            select(item: BaseItemDto(person: element), in: namespace)
        default:
            assertionFailure("Used an unexpected type within a `PagingLibaryView`?")
        }
    }

    private func select(item: BaseItemDto, in namespace: Namespace.ID) {
        switch item.type {
        case .collectionFolder, .folder:
            let viewModel = ItemLibraryViewModel(parent: item, filters: .default)
            router.route(to: .library(viewModel: viewModel), in: namespace)
        default:
            router.route(to: .item(item: item), in: namespace)
        }
    }

    // MARK: layout

    // TODO: rename old "viewType" paramter to "displayType" and sort

    private static func padLayout(
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType,
        listColumnCount: Int
    ) -> PagingCollectionLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            #if os(visionOS)
            .init(
                columns: [GridItem(.adaptive(minimum: 200), spacing: EdgeInsets.edgePadding / 2)],
                lineSpacing: EdgeInsets.edgePadding,
                padding: .init(EdgeInsets.edgePadding)
            )
            #else
            .minWidth(200)
            #endif
        case (.portrait, .grid), (.square, .grid):
            #if os(visionOS)
            .init(
                columns: [GridItem(.adaptive(minimum: 150), spacing: EdgeInsets.edgePadding / 2)],
                lineSpacing: EdgeInsets.edgePadding,
                padding: .init(EdgeInsets.edgePadding)
            )
            #else
            .minWidth(150)
            #endif
        case (_, .list):
            #if os(visionOS)
            .init(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: listColumnCount),
                lineSpacing: 0,
                padding: .zero
            )
            #else
            .columns(listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            #endif
        }
    }

    private static func phoneLayout(
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType
    ) -> PagingCollectionLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            #if os(visionOS)
            .init(
                columns: Array(repeating: GridItem(.flexible(), spacing: EdgeInsets.edgePadding / 2), count: 2),
                lineSpacing: EdgeInsets.edgePadding,
                padding: .init(EdgeInsets.edgePadding)
            )
            #else
            .columns(2)
            #endif
        case (.portrait, .grid):
            #if os(visionOS)
            .init(
                columns: Array(repeating: GridItem(.flexible(), spacing: EdgeInsets.edgePadding / 2), count: 3),
                lineSpacing: EdgeInsets.edgePadding,
                padding: .init(EdgeInsets.edgePadding)
            )
            #else
            .columns(3)
            #endif
        case (.square, .grid):
            #if os(visionOS)
            .init(
                columns: Array(repeating: GridItem(.flexible(), spacing: EdgeInsets.edgePadding / 2), count: 3),
                lineSpacing: EdgeInsets.edgePadding,
                padding: .init(EdgeInsets.edgePadding)
            )
            #else
            .columns(3)
            #endif
        case (_, .list):
            #if os(visionOS)
            .init(
                columns: [GridItem(.flexible(), spacing: 0)],
                lineSpacing: 0,
                padding: .zero
            )
            #else
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            #endif
        }
    }

    // MARK: item view

    // Note: if parent is a folders then other items will have labels,
    //       so an empty content view is necessary

    @ViewBuilder
    private func gridItemView(item: Element, posterType: PosterDisplayType) -> some View {
        PosterButton(
            item: item,
            type: posterType
        ) { namespace in
            action(item, in: namespace)
        } label: {
            if item.showTitle {
                PosterButton<Element>.TitleContentView(title: item.displayTitle)
                    .lineLimit(1, reservesSpace: true)
            } else if viewModel.parent?.libraryType == .folder {
                PosterButton<Element>.TitleContentView(title: item.displayTitle)
                    .lineLimit(1, reservesSpace: true)
                    .hidden()
            }
        }
    }

    @ViewBuilder
    private func listItemView(item: Element, posterType: PosterDisplayType) -> some View {
        LibraryRow(
            item: item,
            posterType: posterType
        ) { namespace in
            action(item, in: namespace)
        }
    }

    @ViewBuilder
    private var elementsView: some View {
        #if os(visionOS)
        ScrollView {
            LazyVGrid(columns: layout.columns, spacing: layout.lineSpacing) {
                ForEach(Array(viewModel.elements.enumerated()), id: \.element.unwrappedIDHashOrZero) { offset, item in
                    let displayType = Defaults[.Customization.Library.rememberLayout] ? displayType : defaultDisplayType
                    let posterType = Defaults[.Customization.Library.rememberLayout] ? posterType : defaultPosterType

                    Group {
                        switch displayType {
                        case .grid:
                            gridItemView(item: item, posterType: posterType)
                        case .list:
                            listItemView(item: item, posterType: posterType)
                        }
                    }
                    .onAppear {
                        if offset >= max(viewModel.elements.count - Self.nextPagePrefetchThreshold, 0) {
                            viewModel.send(.getNextPage)
                        }
                    }
                }
            }
            .padding(layout.padding)
        }
        .scrollIndicators(.hidden)
        #else
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            id: \.unwrappedIDHashOrZero,
            layout: layout
        ) { item in
            let displayType = Defaults[.Customization.Library.rememberLayout] ? displayType : defaultDisplayType
            let posterType = Defaults[.Customization.Library.rememberLayout] ? posterType : defaultPosterType

            switch displayType {
            case .grid:
                gridItemView(item: item, posterType: posterType)
            case .list:
                listItemView(item: item, posterType: posterType)
            }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.getNextPage)
        }
        .proxy(collectionVGridProxy)
        .scrollIndicators(.hidden)
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .content:
            if viewModel.elements.isEmpty {
                ContentUnavailableView(L10n.noItems.localizedCapitalized, systemImage: "rectangle.on.rectangle.slash")
            } else {
                elementsView
            }
        case .initial, .refreshing:
            ProgressView()
        default:
            AssertionFailureView("Expected view for unexpected state")
        }
    }

    // MARK: body

    // TODO: becoming too large for typechecker during development, should break up somehow

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content, .initial, .refreshing:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea(.all, edges: .vertical)
        .letterPickerBar(filterViewModel: viewModel.filterViewModel)
        .onSizeChanged { _, safeArea in
            self.safeArea = safeArea
        }
        .navigationTitle(viewModel.parent?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.send(.refresh)
        }
        .ifLet(viewModel.filterViewModel) { view, filterViewModel in
            view.navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: enabledDrawerFilters
            )
        }
        .backport.onChange(of: defaultDisplayType) { _, newValue in
            guard !Defaults[.Customization.Library.rememberLayout] else { return }

            if UIDevice.isPhone {
                layout = Self.phoneLayout(
                    posterType: defaultPosterType,
                    viewType: newValue
                )
            } else {
                layout = Self.padLayout(
                    posterType: defaultPosterType,
                    viewType: newValue,
                    listColumnCount: defaultListColumnCount
                )
            }
        }
        .backport.onChange(of: defaultListColumnCount) { _, newValue in
            guard !Defaults[.Customization.Library.rememberLayout] else { return }

            if UIDevice.isPad {
                layout = Self.padLayout(
                    posterType: defaultPosterType,
                    viewType: defaultDisplayType,
                    listColumnCount: newValue
                )
            }
        }
        .backport.onChange(of: defaultPosterType) { _, newValue in
            guard !Defaults[.Customization.Library.rememberLayout] else { return }

            if UIDevice.isPhone {
                #if os(visionOS)
                layout = Self.phoneLayout(
                    posterType: newValue,
                    viewType: defaultDisplayType
                )
                #else
                if defaultDisplayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.phoneLayout(
                        posterType: newValue,
                        viewType: defaultDisplayType
                    )
                }
                #endif
            } else {
                #if os(visionOS)
                layout = Self.padLayout(
                    posterType: newValue,
                    viewType: defaultDisplayType,
                    listColumnCount: defaultListColumnCount
                )
                #else
                if defaultDisplayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.padLayout(
                        posterType: newValue,
                        viewType: defaultDisplayType,
                        listColumnCount: defaultListColumnCount
                    )
                }
                #endif
            }
        }
        .backport.onChange(of: displayType) { _, newValue in
            if UIDevice.isPhone {
                layout = Self.phoneLayout(
                    posterType: posterType,
                    viewType: newValue
                )
            } else {
                layout = Self.padLayout(
                    posterType: posterType,
                    viewType: newValue,
                    listColumnCount: listColumnCount
                )
            }
        }
        .backport.onChange(of: listColumnCount) { _, newValue in
            if UIDevice.isPad {
                layout = Self.padLayout(
                    posterType: posterType,
                    viewType: displayType,
                    listColumnCount: newValue
                )
            }
        }
        .backport.onChange(of: posterType) { _, newValue in
            if UIDevice.isPhone {
                #if os(visionOS)
                layout = Self.phoneLayout(
                    posterType: newValue,
                    viewType: displayType
                )
                #else
                if displayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.phoneLayout(
                        posterType: newValue,
                        viewType: displayType
                    )
                }
                #endif
            } else {
                #if os(visionOS)
                layout = Self.padLayout(
                    posterType: newValue,
                    viewType: displayType,
                    listColumnCount: listColumnCount
                )
                #else
                if displayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.padLayout(
                        posterType: newValue,
                        viewType: displayType,
                        listColumnCount: listColumnCount
                    )
                }
                #endif
            }
        }
        .backport.onChange(of: rememberLayout) { _, newValue in
            let newDisplayType = newValue ? displayType : defaultDisplayType
            let newListColumnCount = newValue ? listColumnCount : defaultListColumnCount
            let newPosterType = newValue ? posterType : defaultPosterType

            if UIDevice.isPhone {
                layout = Self.phoneLayout(
                    posterType: newPosterType,
                    viewType: newDisplayType
                )
            } else {
                layout = Self.padLayout(
                    posterType: newPosterType,
                    viewType: newDisplayType,
                    listColumnCount: newListColumnCount
                )
            }
        }
        .backport.onChange(of: viewModel.filterViewModel?.currentFilters) { _, newValue in
            guard let newValue, let id = viewModel.parent?.id else { return }

            if Defaults[.Customization.Library.rememberSort] {
                let newStoredFilters = StoredValues[.User.libraryFilters(parentID: id)]
                    .mutating(\.sortBy, with: newValue.sortBy)
                    .mutating(\.sortOrder, with: newValue.sortOrder)

                StoredValues[.User.libraryFilters(parentID: id)] = newStoredFilters
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .gotRandomItem(item):
                switch item {
                case let item as BaseItemDto:
                    select(item: item, in: namespace)
                case let item as BaseItemPerson:
                    select(item: BaseItemDto(person: item), in: namespace)
                default:
                    assertionFailure("Used an unexpected type within a `PagingLibaryView`?")
                }
            }
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.gettingNextPage)
        ) {
            if Defaults[.Customization.Library.rememberLayout] {
                LibraryViewTypeToggle(
                    posterType: $posterType,
                    viewType: $displayType,
                    listColumnCount: $listColumnCount
                )
            } else {
                LibraryViewTypeToggle(
                    posterType: $defaultPosterType,
                    viewType: $defaultDisplayType,
                    listColumnCount: $defaultListColumnCount
                )
            }

            Button(L10n.random, systemImage: "dice.fill") {
                viewModel.send(.getRandomItem)
            }
            .disabled(viewModel.elements.isEmpty)
        }
    }
}
