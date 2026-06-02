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
@testable import Swiftfin_visionOS
import Testing

@Suite("visionOS video player", .serialized)
struct VisionVideoPlayerTests {

    /// R6: VLCKit is unavailable on visionOS, so the only player type is native.
    @Test
    func `only the native video player type is available`() {
        #expect(VideoPlayerType.allCases == [.native])
    }

    /// R6: the effective player default on visionOS is the native AVKit player.
    @Test
    func `default video player type is native`() {
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
}
