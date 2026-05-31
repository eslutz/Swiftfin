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

extension HomeView {

    struct ContinueWatchingView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: HomeViewModel

        // TODO: see how this looks across multiple screen sizes
        //       alongside PosterHStack + landscape
        // TODO: need better handling for iPadOS + portrait orientation
        private var columnCount: CGFloat {
            if UIDevice.isPhone {
                1.5
            } else {
                3.5
            }
        }

        @ViewBuilder
        private func poster(for item: BaseItemDto) -> some View {
            PosterButton(
                item: item,
                type: .landscape
            ) { namespace in
                router.route(to: .item(item: item), in: namespace)
            } label: {
                if item.type == .episode {
                    PosterButton.EpisodeContentSubtitleContent(item: item)
                } else {
                    PosterButton.TitleSubtitleContentView(item: item)
                }
            }
        }

        @ViewBuilder
        private var collection: some View {
            #if os(visionOS)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: EdgeInsets.edgePadding / 2) {
                    ForEach(viewModel.resumeItems, id: \.unwrappedIDHashOrZero) { item in
                        poster(for: item)
                            .frame(width: 260)
                    }
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
            }
            .scrollIndicators(.hidden)
            .lookToScroll(.horizontal)
            #else
            CollectionHStack(
                uniqueElements: viewModel.resumeItems,
                columns: columnCount
            ) { item in
                poster(for: item)
            }
            .clipsToBounds(false)
            .scrollBehavior(.continuousLeadingEdge)
            #endif
        }

        var body: some View {
            collection
                .contextMenu(for: BaseItemDto.self) { item in
                    Button {
                        viewModel.send(.setIsPlayed(true, item))
                    } label: {
                        Label(L10n.played, systemImage: "checkmark.circle")
                    }

                    Button(role: .destructive) {
                        viewModel.send(.setIsPlayed(false, item))
                    } label: {
                        Label(L10n.unplayed, systemImage: "minus.circle")
                    }
                }
                .posterOverlay(for: BaseItemDto.self) { item in
                    LandscapePosterProgressBar(
                        title: item.progressLabel ?? L10n.continue,
                        progress: (item.userData?.playedPercentage ?? 0) / 100
                    )
                }
        }
    }
}
