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

    private var mediaItems: [MediaViewModel.MediaType] {
        #if os(visionOS)
        // Live TV is not routable on visionOS; exclude it to avoid a visible
        // tile that does nothing when selected.
        viewModel.mediaItems.filter { if case .liveTV = $0 { false } else { true } }
        #else
        Array(viewModel.mediaItems)
        #endif
    }

    private func route(to mediaType: MediaViewModel.MediaType, in namespace: Namespace.ID) {
        switch mediaType {
        case let .collectionFolder(item):
            let viewModel = ItemLibraryViewModel(
                parent: item,
                filters: .default
            )
            router.route(to: .library(viewModel: viewModel), in: namespace)
        case .downloads:
            #if os(iOS)
            router.route(to: .downloadList)
            #else
            break
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
            #if os(visionOS)
            break
            #else
            router.route(to: .liveTV)
            #endif
        }
    }

    @ViewBuilder
    private func mediaItem(for mediaType: MediaViewModel.MediaType) -> some View {
        MediaItem(viewModel: viewModel, type: mediaType) { namespace in
            route(to: mediaType, in: namespace)
        }
    }

    @ViewBuilder
    private var content: some View {
        #if os(visionOS)
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260, maximum: 320), spacing: 24)],
                alignment: .leading,
                spacing: 24
            ) {
                ForEach(mediaItems, id: \.self) { mediaType in
                    mediaItem(for: mediaType)
                        .frame(width: 300)
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .frame(maxWidth: 1120, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.hidden)
        #else
        CollectionVGrid(
            uniqueElements: viewModel.mediaItems,
            layout: layout
        ) { mediaType in
            mediaItem(for: mediaType)
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
        #if !os(visionOS)
            .ignoresSafeArea()
        #endif
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
