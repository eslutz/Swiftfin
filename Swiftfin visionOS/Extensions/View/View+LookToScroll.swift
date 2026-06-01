//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// Look-to-scroll is a visionOS-only affordance, so this lives in the visionOS
// target rather than `Shared/` — keeping iOS/tvOS free of a no-op shim.
extension View {

    @ViewBuilder
    func lookToScroll(_ axes: Axis.Set? = nil) -> some View {
        if #available(visionOS 26.0, *) {
            if let axes {
                scrollInputBehavior(.enabled, for: .look(axes: axes))
            } else {
                scrollInputBehavior(.enabled, for: .look)
            }
        } else {
            self
        }
    }
}
