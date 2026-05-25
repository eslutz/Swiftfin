//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum SearchItemParameters {

    static let previewLimit = 20

    static func items(
        query: String,
        itemType: BaseItemKind,
        filters: ItemFilterCollection,
        page: Int? = nil,
        pageSize: Int = previewLimit
    ) -> Paths.GetItemsParameters {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [itemType]
        parameters.isRecursive = true
        parameters.limit = pageSize
        parameters.searchTerm = query

        if let page {
            parameters.startIndex = page * pageSize
        }

        return apply(filters, to: parameters)
    }

    static func people(
        query: String,
        pageSize: Int = previewLimit
    ) -> Paths.GetPersonsParameters {
        var parameters = Paths.GetPersonsParameters()
        parameters.limit = pageSize
        parameters.searchTerm = query

        return parameters
    }

    private static func apply(
        _ filters: ItemFilterCollection,
        to parameters: Paths.GetItemsParameters
    ) -> Paths.GetItemsParameters {
        var parameters = parameters
        parameters.filters = filters.traits
        parameters.genres = filters.genres.map(\.value)
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.tags = filters.tags.map(\.value)
        parameters.years = filters.years.map(\.intValue)

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

        return parameters
    }
}

@MainActor
final class SearchLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    private let filters: ItemFilterCollection
    private let itemType: BaseItemKind
    private let query: String

    init(
        title: String,
        id: String?,
        query: String,
        itemType: BaseItemKind,
        filters: ItemFilterCollection
    ) {
        self.filters = filters
        self.itemType = itemType
        self.query = query

        super.init(
            parent: TitledLibraryParent(
                displayTitle: title,
                id: id
            ),
            filters: filters
        )
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        let parameters = SearchItemParameters.items(
            query: query,
            itemType: itemType,
            filters: filters,
            page: page,
            pageSize: pageSize
        )
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
