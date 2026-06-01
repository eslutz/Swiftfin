//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemView: View {

    @Router
    private var router

    @StateObject
    private var viewModel: ItemViewModel

    init(item: BaseItemDto) {
        _viewModel = StateObject(wrappedValue: ItemViewModel(item: item))
    }

    private var item: BaseItemDto {
        viewModel.item
    }

    @ViewBuilder
    private var poster: some View {
        ImageView(item.portraitImageSources(maxWidth: 250))
            .failure {
                Image(systemName: item.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
            .frame(width: 250, height: 375)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 30) {
                poster

                VStack(alignment: .leading, spacing: 16) {
                    Text(item.displayTitle)
                        .font(.largeTitle.weight(.bold))

                    if let playButtonItem = viewModel.playButtonItem {
                        Button {
                            let provider = playButtonItem.getPlaybackItemProvider(userSession: viewModel.userSession)
                            router.route(to: .videoPlayer(provider: provider))
                        } label: {
                            Label(L10n.play, systemImage: "play.fill")
                                .frame(maxWidth: 240)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.extraLarge)
                    }

                    if let overview = item.overview {
                        Text(overview)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(EdgeInsets.edgePadding)
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
