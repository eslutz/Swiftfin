//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import PulseUI
import SwiftUI

struct SwiftfinPulseConsoleView: View {

    static let disableSupportPromptsKey = "pulse-disable-support-prompts"

    var body: some View {
        ConsoleView()
            .closeButtonHidden()
            .onAppear {
                UserDefaults.standard.set(true, forKey: Self.disableSupportPromptsKey)
            }
    }
}
