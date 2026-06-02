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
