//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Tracks whether the branded immersive cinema is open. Injected into the
/// environment so any screen can offer the cinema toggle.
@MainActor
final class CinemaModel: ObservableObject {

    static let immersiveSpaceID = "jellyfin-cinema"

    @Published
    private(set) var isOpen = false

    func setOpen(_ open: Bool) {
        isOpen = open
    }
}

/// Opens or closes the branded immersive cinema. The native AVKit player keeps
/// playing in its window, so toggling the cinema never interrupts playback; if
/// the space cannot open, the windowed player is simply left as-is.
struct CinemaToggleButton: View {

    @EnvironmentObject
    private var cinema: CinemaModel

    @Environment(\.openImmersiveSpace)
    private var openImmersiveSpace

    @Environment(\.dismissImmersiveSpace)
    private var dismissImmersiveSpace

    var body: some View {
        Button {
            Task {
                if cinema.isOpen {
                    await dismissImmersiveSpace()
                    cinema.setOpen(false)
                } else if case .opened = await openImmersiveSpace(id: CinemaModel.immersiveSpaceID) {
                    cinema.setOpen(true)
                }
            }
        } label: {
            Label(
                cinema.isOpen ? "Exit Cinema" : "Cinema",
                systemImage: cinema.isOpen ? "xmark.circle" : "movieclapper"
            )
        }
    }
}
