//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

#if os(visionOS)
private struct ChannelCollectionLayout {

    let columns: [GridItem]
    let spacing: CGFloat
}
#else
import CollectionVGrid

private typealias ChannelCollectionLayout = CollectionVGridLayout
#endif

// TODO: remove and flatten to `PagingLibraryView`

// TODO: sorting by number/filtering
//       - see if can use normal filter view model?
//       - how to add custom filters for data context?
// TODO: saving item display type/detailed column count
//       - wait until after user refactor

// Note: Repurposes `LibraryDisplayType` to save from creating a new type.
//       If there are other places where detailed/compact contextually differ
//       from the library types, then create a new type and use it here.
//       - list: detailed
//       - grid: compact

struct ChannelLibraryView: View {

    @Router
    private var router

    @State
    private var channelDisplayType: LibraryDisplayType = .list
    @State
    private var layout: ChannelCollectionLayout

    @StateObject
    private var viewModel = ChannelLibraryViewModel()

    // MARK: init

    init() {
        if UIDevice.isPhone {
            layout = Self.padlayout(channelDisplayType: .list)
        } else {
            layout = Self.phonelayout(channelDisplayType: .list)
        }
    }

    // MARK: layout

    private static func padlayout(
        channelDisplayType: LibraryDisplayType
    ) -> ChannelCollectionLayout {
        switch channelDisplayType {
        case .grid:
            #if os(visionOS)
            .init(columns: [GridItem(.adaptive(minimum: 150), spacing: EdgeInsets.edgePadding)], spacing: EdgeInsets.edgePadding)
            #else
            .minWidth(150)
            #endif
        case .list:
            #if os(visionOS)
            .init(columns: [GridItem(.adaptive(minimum: 250), spacing: EdgeInsets.edgePadding)], spacing: EdgeInsets.edgePadding)
            #else
            .minWidth(250)
            #endif
        }
    }

    private static func phonelayout(
        channelDisplayType: LibraryDisplayType
    ) -> ChannelCollectionLayout {
        switch channelDisplayType {
        case .grid:
            #if os(visionOS)
            .init(columns: [GridItem(.adaptive(minimum: 150), spacing: EdgeInsets.edgePadding)], spacing: EdgeInsets.edgePadding)
            #else
            .columns(3)
            #endif
        case .list:
            #if os(visionOS)
            .init(columns: [GridItem(.flexible())], spacing: EdgeInsets.edgePadding)
            #else
            .columns(1)
            #endif
        }
    }

    // MARK: item view

    private func compactChannelView(channel: ChannelProgram) -> some View {
        CompactChannelView(channel: channel.channel) {
            router.route(
                to: .videoPlayer(
                    provider: channel.channel.getPlaybackItemProvider(
                        userSession: viewModel.userSession
                    )
                )
            )
        }
    }

    private func detailedChannelView(channel: ChannelProgram) -> some View {
        DetailedChannelView(channel: channel) {
            router.route(
                to: .videoPlayer(
                    provider: channel.channel.getPlaybackItemProvider(
                        userSession: viewModel.userSession
                    )
                )
            )
        }
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(visionOS)
        ScrollView {
            LazyVGrid(columns: layout.columns, spacing: layout.spacing) {
                ForEach(Array(viewModel.elements.enumerated()), id: \.element.unwrappedIDHashOrZero) { offset, channel in
                    Group {
                        switch channelDisplayType {
                        case .grid:
                            compactChannelView(channel: channel)
                        case .list:
                            detailedChannelView(channel: channel)
                        }
                    }
                    .onAppear {
                        if offset == viewModel.elements.count - 1 {
                            viewModel.send(.getNextPage)
                        }
                    }
                }
            }
            .padding(EdgeInsets.edgePadding)
        }
        .scrollIndicators(.hidden)
        #else
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            layout: layout
        ) { channel in
            switch channelDisplayType {
            case .grid:
                compactChannelView(channel: channel)
            case .list:
                detailedChannelView(channel: channel)
            }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.getNextPage)
        }
        #endif
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    ContentUnavailableView(L10n.noChannels.localizedCapitalized, systemImage: "antenna.radiowaves.left.and.right")
                } else {
                    contentView
                }
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .navigationTitle(L10n.channels)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onChange(of: channelDisplayType) { newValue in
            if UIDevice.isPhone {
                layout = Self.phonelayout(channelDisplayType: newValue)
            } else {
                layout = Self.padlayout(channelDisplayType: newValue)
            }
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
        .sinceLastDisappear { interval in
            // refresh after 3 hours
            if interval >= 10800 {
                viewModel.send(.refresh)
            }
        }
        .topBarTrailing {

            if viewModel.backgroundStates.contains(.gettingNextPage) {
                ProgressView()
            }

            Menu {
                // We repurposed `LibraryDisplayType` but want different labels
                Picker(L10n.channelDisplay, selection: $channelDisplayType) {

                    Label(L10n.compact, systemImage: LibraryDisplayType.grid.systemImage)
                        .tag(LibraryDisplayType.grid)

                    Label(L10n.detailed, systemImage: LibraryDisplayType.list.systemImage)
                        .tag(LibraryDisplayType.list)
                }
            } label: {
                Label(
                    channelDisplayType.displayTitle,
                    systemImage: channelDisplayType.systemImage
                )
            }
        }
    }
}
