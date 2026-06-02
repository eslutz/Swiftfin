//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import KeychainSwift
@testable import Swiftfin_visionOS

/// A keychain that always returns a token, so session-backed code such as
/// `UserState.accessToken` (which asserts when the token is missing) is
/// satisfied in the unit-test environment.
final class MockKeychain: KeychainSwift {

    override func get(_ key: String) -> String? {
        "test-access-token"
    }
}

/// Shared setup for visionOS unit tests that exercise code touching the user
/// session. Install the mock keychain in a test's setup and tear it down after.
enum TestSupport {

    static func installMockSession() {
        Container.shared.keychainService.register { MockKeychain() }
    }

    static func tearDown() {
        Container.shared.keychainService.reset()
        Container.shared.currentUserSession.reset()
    }
}
