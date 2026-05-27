//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    @ViewBuilder
    func lookToScroll(_ axes: Axis.Set? = nil) -> some View {
        #if os(visionOS)
        if #available(visionOS 26.0, *) {
            if let axes {
                scrollInputBehavior(.enabled, for: .look(axes: axes))
            } else {
                scrollInputBehavior(.enabled, for: .look)
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}
