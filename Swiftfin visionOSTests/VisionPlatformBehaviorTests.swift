//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
@testable import Swiftfin_visionOS
import SwiftUI
import Testing
import UIKit

@Suite("visionOS platform behavior")
struct VisionPlatformBehaviorTests {

    @Test
    func `device helpers report vision OS platform`() {
        #expect(UIDevice.isVision)
        #expect(UIDevice.isPad)
        #expect(!UIDevice.isPhone)
        #expect(!UIDevice.isTV)
        #expect(!UIDevice.hasNotch)
        #expect(UIDevice.platform == L10n.visionOS)
    }

    @Test
    func `platform screen scale does not downscale`() {
        #expect(PlatformScreen.scale(100) >= 100)
    }

    @Test
    @MainActor
    func `server check view can render after current session is cleared`() {
        let originalSignInState = Defaults[.lastSignedInUserID]

        defer {
            Defaults[.lastSignedInUserID] = originalSignInState
            Container.shared.currentUserSession.reset()
        }

        Defaults[.lastSignedInUserID] = .signedOut
        Container.shared.currentUserSession.reset()

        let hostingController = UIHostingController(rootView: NavigationStack {
            ServerCheckView()
        })

        _ = hostingController.view
        hostingController.view.layoutIfNeeded()
    }

    @Test
    @MainActor
    func `server check action ignores requests without a current session`() async {
        let originalSignInState = Defaults[.lastSignedInUserID]

        defer {
            Defaults[.lastSignedInUserID] = originalSignInState
            Container.shared.currentUserSession.reset()
        }

        Defaults[.lastSignedInUserID] = .signedOut
        Container.shared.currentUserSession.reset()

        let viewModel = ServerCheckViewModel()
        await viewModel.checkServer()
    }
}

@Suite("visionOS video player defaults", .serialized)
struct VisionVideoPlayerDefaultsTests {

    @Test
    func `vision OS only exposes native video player`() {
        #expect(VideoPlayerType.allCases == [.native])
    }

    @Test
    func `vision OS default video player type is native`() {
        let originalSignInState = Defaults[.lastSignedInUserID]
        let temporaryUserID = "visionos-tests-\(UUID().uuidString)"

        defer {
            Defaults[.lastSignedInUserID] = originalSignInState
            UserDefaults.standard.removePersistentDomain(forName: temporaryUserID)
            Container.shared.currentUserSession.reset()
        }

        Defaults[.lastSignedInUserID] = .signedIn(userID: temporaryUserID)

        #expect(Defaults[.VideoPlayer.videoPlayerType] == .native)
    }

    @Test
    func `vision OS uses native player for AVKit immersive experiences`() {
        let originalSignInState = Defaults[.lastSignedInUserID]
        let temporaryUserID = "visionos-tests-\(UUID().uuidString)"

        defer {
            Defaults[.lastSignedInUserID] = originalSignInState
            UserDefaults.standard.removePersistentDomain(forName: temporaryUserID)
            Container.shared.currentUserSession.reset()
        }

        Defaults[.lastSignedInUserID] = .signedIn(userID: temporaryUserID)

        #expect(VideoPlayerType.allCases == [.native])
        #expect(Defaults[.VideoPlayer.videoPlayerType] == .native)
    }
}

@Suite("visionOS public user identity")
struct VisionPublicUserIdentityTests {

    @Test
    func `public user identity prefers server id`() {
        #expect(UserSignInViewModel.publicUserIdentifier(id: "abc", name: "Lindsey") == "abc")
    }

    @Test
    func `public user identity falls back to normalized name`() {
        #expect(UserSignInViewModel.publicUserIdentifier(id: nil, name: " Eric ") == "public-user-eric")
    }

    @Test
    func `public user identity ignores blank id`() {
        #expect(UserSignInViewModel.publicUserIdentifier(id: "  ", name: "Claire") == "public-user-claire")
    }

    @Test
    func `public user identity has stable unknown fallback`() {
        #expect(UserSignInViewModel.publicUserIdentifier(id: nil, name: nil) == "public-user-unknown")
    }

    @Test
    func `public user identities disambiguate duplicate fallback identifiers`() {
        let users = [
            UserDto(id: nil, name: " Alice "),
            UserDto(id: nil, name: "alice"),
            UserDto(id: nil, name: "Bob"),
        ]

        #expect(
            UserSignInViewModel.publicUserIdentifiers(for: users) == [
                "public-user-alice-0",
                "public-user-alice-1",
                "public-user-bob",
            ]
        )
    }
}

@Suite("home view model played status")
struct HomeViewModelPlayedStatusTests {

    @Test
    func `successful played status update schedules background refresh`() {
        #expect(HomeViewModel.setIsPlayedCompletionAction(error: nil) == .backgroundRefresh)
    }

    @Test
    func `failed played status update emits error action`() {
        #expect(
            HomeViewModel.setIsPlayedCompletionAction(error: PlayedStatusError()) == .error(.init("Unable to update played status"))
        )
    }

    private struct PlayedStatusError: LocalizedError {
        var errorDescription: String? {
            "Unable to update played status"
        }
    }
}

@Suite("visionOS server connection", .serialized)
@MainActor
struct VisionServerConnectionTests {

    @Test
    func `saving a new current server url persists url and current selection`() async throws {
        try await SwiftfinStore.setupDataStack()

        let originalServers = StoredValues[.Server.servers]
        let originalSignInState = Defaults[.lastSignedInUserID]
        defer {
            StoredValues[.Server.servers] = originalServers
            Defaults[.lastSignedInUserID] = originalSignInState
            Container.shared.currentUserSession.reset()
        }

        Defaults[.lastSignedInUserID] = .signedOut
        Container.shared.currentUserSession.reset()

        let originalURL = try #require(URL(string: "http://192.168.1.10:8096"))
        let newURL = try #require(URL(string: "https://jellyfin.example.com"))
        let server = ServerState(
            urls: [originalURL],
            currentURL: originalURL,
            name: "Test Server",
            id: "visionos-server-\(UUID().uuidString)",
            userIDs: []
        )
        StoredValues[.Server.servers] = [server]

        let viewModel = ServerConnectionViewModel(server: server)
        try viewModel.saveCurrentURL(to: newURL)

        let storedServer = try #require(StoredValues[.Server.servers].first { $0.id == server.id })
        #expect(storedServer.currentURL == newURL)
        #expect(storedServer.urls.contains(originalURL))
        #expect(storedServer.urls.contains(newURL))
        #expect(viewModel.server.currentURL == newURL)
    }
}

@Suite("visionOS search history")
struct VisionSearchHistoryTests {

    @Test
    func `search history deduplicates case insensitively`() {
        let result = SearchViewModel.updatedSearchHistory(["Prey", "Tokyo Zombie"], inserting: "prey")

        #expect(result == ["prey", "Tokyo Zombie"])
    }

    @Test
    func `search history caps at ten entries`() {
        let history = (0 ..< 12).map { "Item \($0)" }
        let result = SearchViewModel.updatedSearchHistory(history, inserting: "Newest")

        #expect(result.count == 10)
        #expect(result.first == "Newest")
    }

    @Test
    func `search history ignores blank entries`() {
        let history = ["Prey"]
        let result = SearchViewModel.updatedSearchHistory(history, inserting: "  ")

        #expect(result == history)
    }
}

@Suite("visionOS search library parameters")
struct VisionSearchLibraryParameterTests {

    @Test
    func `search paging parameters preserve query filters and page offset`() {
        var filters = ItemFilterCollection.default
        filters.genres = ["Comedy"]
        filters.sortBy = [.dateCreated]
        filters.sortOrder = [.descending]
        filters.tags = ["Classic"]
        filters.traits = [.isFavorite]
        filters.years = [1934]

        let firstPage = SearchItemParameters.items(
            query: "The Three Stooges",
            itemType: .episode,
            filters: filters,
            page: 0,
            pageSize: 50
        )
        let secondPage = SearchItemParameters.items(
            query: "The Three Stooges",
            itemType: .episode,
            filters: filters,
            page: 1,
            pageSize: 50
        )

        #expect(firstPage.searchTerm == "The Three Stooges")
        #expect(firstPage.includeItemTypes == [.episode])
        #expect(firstPage.limit == 50)
        #expect(firstPage.startIndex == 0)
        #expect(firstPage.isRecursive == true)
        #expect(firstPage.genres == ["Comedy"])
        #expect(firstPage.sortBy == [.dateCreated])
        #expect(firstPage.sortOrder == [.descending])
        #expect(firstPage.tags == ["Classic"])
        #expect(firstPage.filters == [.isFavorite])
        #expect(firstPage.years == [1934])
        #expect(secondPage.startIndex == 50)
    }

    @Test
    @MainActor
    func `search result paging parameters use updated library filters`() throws {
        var originalFilters = ItemFilterCollection.default
        originalFilters.genres = ["Comedy"]

        var updatedFilters = ItemFilterCollection.default
        updatedFilters.genres = ["Drama"]
        updatedFilters.sortBy = [.dateCreated]
        updatedFilters.sortOrder = [.descending]
        updatedFilters.tags = ["Classic"]
        updatedFilters.traits = [.isFavorite]
        updatedFilters.years = [1934]

        let viewModel = SearchLibraryViewModel(
            title: "Movies",
            id: nil,
            query: "The Three Stooges",
            itemType: .movie,
            filters: originalFilters
        )

        let filterViewModel = try #require(viewModel.filterViewModel)
        filterViewModel.currentFilters = updatedFilters

        let parameters = viewModel.itemParameters(for: 1)

        #expect(parameters.genres == ["Drama"])
        #expect(parameters.sortBy == [.dateCreated])
        #expect(parameters.sortOrder == [.descending])
        #expect(parameters.tags == ["Classic"])
        #expect(parameters.filters == [.isFavorite])
        #expect(parameters.years == [1934])
        #expect(parameters.startIndex == viewModel.pageSize)
    }
}

@Suite("visionOS library layout controls")
struct VisionLibraryLayoutControlTests {

    @Test
    func `vision OS hides list column controls`() {
        #expect(PagingLibraryView<BaseItemDto>.LibraryViewTypeToggle.supportsListColumnControls == false)
    }

    @Test
    func `vision OS exposes library layout controls inline`() {
        #expect(PagingLibraryView<BaseItemDto>.LibraryViewTypeToggle.presentsInlineControls)
    }

    @Test
    func `vision OS hides random library action`() {
        #expect(PagingLibraryView<BaseItemDto>.supportsRandomItemAction == false)
    }
}

@Suite("visionOS settings controls")
struct VisionSettingsControlTests {

    @Test
    func `vision OS hides liquid glass debug toggle`() {
        #expect(DebugSettingsView.showsLiquidGlassToggle == false)
    }
}

@Suite("app settings splashscreen selection")
struct AppSettingsSplashscreenSelectionTests {

    @Test
    func `normalization preserves all servers splashscreen selection`() throws {
        let servers = try [
            Self.server(id: "server-1", name: "Server 1"),
        ]

        let selection = AppSettingsView.normalizedSplashscreenServerSelection(
            .all,
            servers: servers
        )

        #expect(selection == .all)
    }

    @Test
    func `normalization replaces missing concrete splashscreen server`() throws {
        let servers = try [
            Self.server(id: "server-1", name: "Server 1"),
        ]

        let selection = AppSettingsView.normalizedSplashscreenServerSelection(
            .server(id: "missing-server"),
            servers: servers
        )

        #expect(selection == .server(id: "server-1"))
    }

    private static func server(id: String, name: String) throws -> ServerState {
        let url = try #require(URL(string: "https://\(id).example.com"))
        return ServerState(
            urls: [url],
            currentURL: url,
            name: name,
            id: id,
            userIDs: []
        )
    }
}

@Suite("paging library view model")
@MainActor
struct PagingLibraryViewModelTests {

    @Test
    func `get next page ignores duplicate request while page is loading`() async throws {
        let viewModel = RecordingPagingLibraryViewModel(
            pageDelayNanoseconds: 50_000_000,
            pageResults: [
                Self.posters(0 ..< 50),
                Self.posters(50 ..< 100),
            ]
        )

        _ = viewModel.respond(to: .refresh)
        try await Self.waitForRequestedPages(in: viewModel, expectedPages: [0])
        viewModel.resetRequestedPages()

        _ = viewModel.respond(to: .getNextPage)
        try await Self.waitForBackgroundState(.gettingNextPage, in: viewModel)

        _ = viewModel.respond(to: .getNextPage)

        try await Self.waitForBackgroundWorkToFinish(in: viewModel)

        #expect(viewModel.requestedPages == [1])
    }

    @Test
    func `refresh clears stale next page loading state`() async throws {
        let viewModel = RecordingPagingLibraryViewModel(
            pageResults: [Self.posters(0 ..< 50)]
        )
        viewModel.backgroundStates.insert(.gettingNextPage)

        let state = viewModel.respond(to: .refresh)

        #expect(state == .refreshing)
        #expect(!viewModel.backgroundStates.contains(.gettingNextPage))

        try await Self.waitForRequestedPages(in: viewModel, expectedPages: [0])

        #expect(viewModel.requestedPages == [0])
        #expect(!viewModel.backgroundStates.contains(.gettingNextPage))
    }

    private static func posters(_ range: Range<Int>) -> [TestPoster] {
        range.map(TestPoster.init(id:))
    }

    private static func waitForBackgroundWorkToFinish(
        in viewModel: RecordingPagingLibraryViewModel
    ) async throws {
        for _ in 0 ..< 100 {
            if !viewModel.backgroundStates.contains(.gettingNextPage) {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(Bool(false), "Timed out waiting for next-page background work to finish")
    }

    private static func waitForBackgroundState(
        _ backgroundState: PagingLibraryViewModel<TestPoster>.BackgroundState,
        in viewModel: RecordingPagingLibraryViewModel
    ) async throws {
        for _ in 0 ..< 100 {
            if viewModel.backgroundStates.contains(backgroundState) {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(Bool(false), "Timed out waiting for the expected background state")
    }

    private static func waitForRequestedPages(
        in viewModel: RecordingPagingLibraryViewModel,
        expectedPages: [Int]
    ) async throws {
        for _ in 0 ..< 100 {
            if viewModel.requestedPages == expectedPages {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(Bool(false), "Timed out waiting for requested pages")
    }
}

private struct TestPoster: Poster {

    typealias ImageBody = Image

    let id: Int

    var displayTitle: String {
        String(id)
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait
    }

    var systemImage: String {
        "photo"
    }

    var unwrappedIDHashOrZero: Int {
        id
    }
}

@MainActor
private final class RecordingPagingLibraryViewModel: PagingLibraryViewModel<TestPoster> {

    private let pageDelayNanoseconds: UInt64
    private let pageResults: [[TestPoster]]
    private(set) var requestedPages: [Int] = []

    init(
        pageDelayNanoseconds: UInt64 = 0,
        pageResults: [[TestPoster]]
    ) {
        self.pageDelayNanoseconds = pageDelayNanoseconds
        self.pageResults = pageResults

        super.init(pageSize: 50)
    }

    override func get(page: Int) async throws -> [TestPoster] {
        requestedPages.append(page)

        if pageDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: pageDelayNanoseconds)
        }

        guard pageResults.indices.contains(page) else {
            return []
        }

        return pageResults[page]
    }

    func resetRequestedPages() {
        requestedPages.removeAll()
    }
}
