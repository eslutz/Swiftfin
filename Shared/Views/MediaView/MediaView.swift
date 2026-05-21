//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import JellyfinAPI
import SwiftUI

#if !os(visionOS)
import CollectionVGrid
#endif

struct MediaView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = MediaViewModel()

    #if !os(visionOS)
    private var layout: CollectionVGridLayout {
        if UIDevice.isTV {
            .columns(4, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        } else if UIDevice.isPad {
            .minWidth(200)
        } else {
            .columns(2)
        }
    }
    #endif

    @ViewBuilder
    private var content: some View {
        #if os(visionOS)
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200), spacing: EdgeInsets.edgePadding)],
                spacing: EdgeInsets.edgePadding
            ) {
                ForEach(viewModel.mediaItems, id: \.self) { mediaType in
                    MediaItem(viewModel: viewModel, type: mediaType) { namespace in
                        switch mediaType {
                        case let .collectionFolder(item):
                            let viewModel = ItemLibraryViewModel(
                                parent: item,
                                filters: .default
                            )
                            router.route(to: .library(viewModel: viewModel), in: namespace)
                        case .downloads:
                            #if os(visionOS)
                            break
                            #else
                            router.route(to: .downloadList)
                            #endif
                        case .favorites:
                            // TODO: favorites should have its own view instead of a library
                            let viewModel = ItemLibraryViewModel(
                                title: L10n.favorites,
                                id: "favorites",
                                filters: .favorites
                            )
                            router.route(to: .library(viewModel: viewModel), in: namespace)
                        case .liveTV:
                            router.route(to: .liveTV)
                        }
                    }
                }
            }
            .padding(EdgeInsets.edgePadding)
        }
        .scrollIndicators(.hidden)
        #else
        CollectionVGrid(
            uniqueElements: viewModel.mediaItems,
            layout: layout
        ) { mediaType in
            MediaItem(viewModel: viewModel, type: mediaType) { namespace in
                switch mediaType {
                case let .collectionFolder(item):
                    let viewModel = ItemLibraryViewModel(
                        parent: item,
                        filters: .default
                    )
                    router.route(to: .library(viewModel: viewModel), in: namespace)
                case .downloads:
                    #if os(visionOS)
                    break
                    #else
                    router.route(to: .downloadList)
                    #endif
                case .favorites:
                    // TODO: favorites should have its own view instead of a library
                    let viewModel = ItemLibraryViewModel(
                        title: L10n.favorites,
                        id: "favorites",
                        filters: .favorites
                    )
                    router.route(to: .library(viewModel: viewModel), in: namespace)
                case .liveTV:
                    router.route(to: .liveTV)
                }
            }
        }
        #endif
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .initial:
                content
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia.localizedCapitalized)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .if(UIDevice.isTV) { view in
            view.toolbar(.hidden, for: .navigationBar)
        }
    }
}
