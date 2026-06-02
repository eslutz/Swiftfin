//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

@main
struct SwiftfinApp: App {

    @StateObject
    private var valueObservation = ValueObservation()

    @StateObject
    private var cinemaModel = CinemaModel()

    @State
    private var hasEnteredBackground = false

    init() {
        Self.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .lookToScroll()
                .onScenePhase(.background) {
                    hasEnteredBackground = true
                    Defaults[.backgroundTimeStamp] = Date.now
                }
                .onScenePhase(.active) {
                    guard hasEnteredBackground else { return }

                    hasEnteredBackground = false

                    // TODO: needs to check if any background playback is happening
                    let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])

                    if Defaults[.signOutOnBackground], backgroundedInterval > Defaults[.backgroundSignOutInterval] {
                        Defaults[.lastSignedInUserID] = .signedOut
                        Container.shared.currentUserSession.reset()
                        Notifications[.didSignOut].post()
                    }
                }
                .environmentObject(cinemaModel)
        }
        .defaultSize(width: 1280, height: 900)

        // Branded immersive "Jellyfin Cinema" — an opt-in environment that
        // surrounds the windowed AVKit player. Progressive immersion lets the
        // viewer dial the room in/out with the Digital Crown for comfort.
        ImmersiveSpace(id: CinemaModel.immersiveSpaceID) {
            JellyfinCinemaImmersiveView()
        }
        .immersionStyle(selection: .constant(.progressive), in: .progressive)
    }
}
