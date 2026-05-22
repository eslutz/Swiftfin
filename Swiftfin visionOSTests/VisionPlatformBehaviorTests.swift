//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
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
        }

        Defaults[.lastSignedInUserID] = .signedIn(userID: temporaryUserID)

        #expect(Defaults[.VideoPlayer.videoPlayerType] == .native)
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
