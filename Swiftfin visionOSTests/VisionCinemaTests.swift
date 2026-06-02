//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_visionOS
import Testing

@Suite("visionOS cinema")
@MainActor
struct VisionCinemaTests {

    @Test
    func `cinema model starts closed`() {
        #expect(CinemaModel().isOpen == false)
    }

    @Test
    func `cinema model tracks its open state`() {
        let model = CinemaModel()

        model.setOpen(true)
        #expect(model.isOpen)

        model.setOpen(false)
        #expect(model.isOpen == false)
    }

    @Test
    func `cinema immersive space identifier is stable`() {
        #expect(CinemaModel.immersiveSpaceID == "jellyfin-cinema")
    }
}
