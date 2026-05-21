//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#if !os(visionOS)
import CollectionHStack
#endif

// TODO: The content/loading/error states are implemented as different CollectionHStacks because it was just easy.
//       A theoretically better implementation would be a single CollectionHStack with cards that represent the state instead.
extension SeriesEpisodeSelector {

    struct EpisodeHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        @State
        private var didScrollToPlayButtonItem = false

        #if !os(visionOS)
        @StateObject
        private var proxy = CollectionHStackProxy()
        #endif

        let playButtonItem: BaseItemDto?

        private func contentView(viewModel: SeasonItemViewModel) -> some View {
            #if os(visionOS)
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: EdgeInsets.edgePadding / 2) {
                        ForEach(viewModel.elements, id: \.unwrappedIDHashOrZero) { episode in
                            SeriesEpisodeSelector.EpisodeCard(episode: episode)
                                .frame(width: 320)
                                .id(episode.unwrappedIDHashOrZero)
                        }
                    }
                    .padding(.horizontal, EdgeInsets.edgePadding)
                }
                .scrollIndicators(.hidden)
                .onFirstAppear {
                    guard !didScrollToPlayButtonItem else { return }
                    didScrollToPlayButtonItem = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        guard let playButtonItem else { return }
                        proxy.scrollTo(playButtonItem.unwrappedIDHashOrZero)
                    }
                }
            }
            #else
            CollectionHStack(
                uniqueElements: viewModel.elements,
                id: \.unwrappedIDHashOrZero,
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { episode in
                SeriesEpisodeSelector.EpisodeCard(episode: episode)
            }
            .clipsToBounds(false)
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .proxy(proxy)
            .onFirstAppear {
                guard !didScrollToPlayButtonItem else { return }
                didScrollToPlayButtonItem = true

                // good enough?
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let playButtonItem else { return }
                    proxy.scrollTo(id: playButtonItem.unwrappedIDHashOrZero, animated: false)
                }
            }
            #endif
        }

        var body: some View {
            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    EmptyHStack()
                } else {
                    contentView(viewModel: viewModel)
                }
            case let .error(error):
                ErrorHStack(viewModel: viewModel, error: error)
            case .initial, .refreshing:
                LoadingHStack()
            }
        }
    }

    struct EmptyHStack: View {

        var body: some View {
            #if os(visionOS)
            ScrollView(.horizontal) {
                LazyHStack {
                    SeriesEpisodeSelector.EmptyCard()
                        .frame(width: 320)
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
            #else
            CollectionHStack(
                count: 1,
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { _ in
                SeriesEpisodeSelector.EmptyCard()
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
            #endif
        }
    }

    // TODO: better refresh design
    struct ErrorHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        let error: ErrorMessage

        var body: some View {
            #if os(visionOS)
            ScrollView(.horizontal) {
                LazyHStack {
                    SeriesEpisodeSelector.ErrorCard(error: error) {
                        viewModel.send(.refresh)
                    }
                    .frame(width: 320)
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
            #else
            CollectionHStack(
                count: 1,
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { _ in
                SeriesEpisodeSelector.ErrorCard(error: error) {
                    viewModel.send(.refresh)
                }
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
            #endif
        }
    }

    struct LoadingHStack: View {

        var body: some View {
            #if os(visionOS)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: EdgeInsets.edgePadding / 2) {
                    ForEach(0 ..< Int.random(in: 2 ..< 5), id: \.self) { _ in
                        SeriesEpisodeSelector.LoadingCard()
                            .frame(width: 320)
                    }
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
            #else
            CollectionHStack(
                count: Int.random(in: 2 ..< 5),
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { _ in
                SeriesEpisodeSelector.LoadingCard()
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
            #endif
        }
    }
}
