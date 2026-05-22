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

    @State
    private var hasEnteredBackground = false

    init() {
        Self.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
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
        }
        .defaultSize(width: 1280, height: 900)
    }
}
