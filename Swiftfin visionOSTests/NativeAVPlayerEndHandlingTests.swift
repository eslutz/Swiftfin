//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Defaults
import JellyfinAPI
@testable import Swiftfin_visionOS
import Testing

@Suite("native AVPlayer end handling")
@MainActor
struct NativeAVPlayerEndHandlingTests {

    @Test
    func `play to end notification completes native playback`() async throws {
        let originalSendProgressReports = Defaults[.sendProgressReports]
        Defaults[.sendProgressReports] = false
        TestSupport.installMockSession()
        defer {
            Defaults[.sendProgressReports] = originalSendProgressReports
            TestSupport.tearDown()
        }

        let proxy = AVMediaPlayerProxy()
        let manager = MediaPlayerManager(playbackItem: Self.playbackItem)
        manager.proxy = proxy
        manager.seconds = .seconds(59)

        guard let currentItem = proxy.player.currentItem else {
            Issue.record("Expected native proxy to create an AVPlayerItem")
            return
        }

        NotificationCenter.default.post(
            name: AVPlayerItem.didPlayToEndTimeNotification,
            object: currentItem
        )

        try await Self.waitForStoppedState(in: manager)

        #expect(manager.seconds == .seconds(60))
    }

    private static var playbackItem: MediaPlayerItem {
        var baseItem = BaseItemDto(id: "episode-1", name: "Episode 1")
        baseItem.type = .episode
        baseItem.runTimeTicks = Duration.seconds(60).ticks

        var mediaSource = MediaSourceInfo()
        mediaSource.id = "media-source-1"

        return MediaPlayerItem(
            baseItem: baseItem,
            mediaSource: mediaSource,
            playSessionID: "play-session-1",
            url: URL(string: "https://example.com/video.mp4")!
        )
    }

    private static func waitForStoppedState(in manager: MediaPlayerManager) async throws {
        for _ in 0 ..< 100 {
            if manager.state == .stopped {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        Issue.record("Timed out waiting for native playback to stop after AVPlayerItem end notification")
    }
}
