//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @Router
    private var router

    @State
    private var searchQuery = ""

    @StateObject
    private var viewModel = SearchViewModel(filterViewModel: .init())

    private func select(_ item: BaseItemDto) {
        switch item.type {
        case .program, .tvChannel:
            let provider = item.getPlaybackItemProvider(userSession: viewModel.userSession)
            router.route(to: .videoPlayer(provider: provider))
        default:
            router.route(to: .item(item: item))
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ type: BaseItemKind, landscape: Bool = false) -> some View {
        if let items = viewModel.items[type], items.isNotEmpty {
            PosterRail(title: title, items: items, landscape: landscape, action: select)
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                section(L10n.movies, .movie)
                section(L10n.tvShows, .series)
                section(L10n.collections, .boxSet)
                section(L10n.episodes, .episode, landscape: true)
                section(L10n.musicVideos, .musicVideo, landscape: true)
                section(L10n.videos, .video, landscape: true)
                section(L10n.programs, .program, landscape: true)
                section(L10n.channels, .tvChannel, landscape: true)
                section(L10n.artists, .musicArtist)
                section(L10n.people, .person)
            }
            .padding(.vertical, EdgeInsets.edgePadding)
        }
        .lookToScroll()
    }

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.suggestions) { item in
                Button(item.displayTitle) {
                    searchQuery = item.displayTitle
                }
                .buttonStyle(.bordered)
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map { ErrorView(error: $0) }
            case .initial:
                if viewModel.hasNoResults {
                    if viewModel.canSearch {
                        ContentUnavailableView.search
                    } else {
                        suggestionsView
                    }
                } else {
                    resultsView
                }
            case .searching:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.search)
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .onChange(of: searchQuery) { _, newValue in
            viewModel.search(query: newValue)
        }
        .searchable(text: $searchQuery, prompt: L10n.search)
    }
}
