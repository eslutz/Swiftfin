//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct HomeView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = HomeViewModel()

    private func select(_ item: BaseItemDto) {
        router.route(to: .item(item: item))
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {

                PosterRail(
                    title: L10n.continue,
                    items: Array(viewModel.resumeItems),
                    landscape: true,
                    action: select
                )

                PosterRail(
                    title: L10n.nextUp,
                    items: Array(viewModel.nextUpViewModel.elements),
                    action: select
                )

                PosterRail(
                    title: L10n.recentlyAdded,
                    items: Array(viewModel.recentlyAddedViewModel.elements),
                    action: select
                )

                ForEach(viewModel.libraries) { library in
                    PosterRail(
                        title: library.parent?.displayTitle ?? L10n.library,
                        items: Array(library.elements),
                        action: select
                    )
                }
            }
            .padding(.vertical, EdgeInsets.edgePadding)
        }
        .lookToScroll()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .navigationTitle(L10n.home)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.settings, systemImage: "gearshape") {
                    router.route(to: .settings)
                }
            }
        }
    }
}
