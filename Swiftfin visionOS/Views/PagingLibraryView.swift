//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PagingLibraryView<Element: Poster>: View {

    @Router
    private var router

    @StateObject
    private var viewModel: PagingLibraryViewModel<Element>

    init(viewModel: PagingLibraryViewModel<Element>) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 24)]

    private func select(_ item: Element) {
        if let baseItem = item as? BaseItemDto {
            router.route(to: .item(item: baseItem))
        }
    }

    @ViewBuilder
    private var gridView: some View {
        VisionVGrid(
            viewModel.elements,
            id: \.unwrappedIDHashOrZero,
            columns: columns,
            spacing: 24,
            padding: EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24),
            onReachedEnd: { viewModel.send(.getNextPage) }
        ) { item in
            PosterButton(item: item, action: select)
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                gridView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .navigationTitle(viewModel.parent?.displayTitle ?? L10n.library)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
