//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_visionOS
import SwiftUI
import Testing
import UIKit

@Suite("visionOS look to scroll")
@MainActor
struct VisionLookToScrollTests {

    @Test
    func `automatic look to scroll modifier renders a scroll view`() {
        let hostingController = UIHostingController(rootView: ScrollView {
            Color.clear
                .frame(width: 1, height: 1)
        }
        .lookToScroll())

        _ = hostingController.view
        hostingController.view.layoutIfNeeded()
    }

    @Test
    func `horizontal look to scroll modifier renders a horizontal scroll view`() {
        let hostingController = UIHostingController(rootView: ScrollView(.horizontal) {
            HStack {
                Color.clear
                    .frame(width: 1, height: 1)
                Color.clear
                    .frame(width: 1, height: 1)
            }
        }
        .lookToScroll(.horizontal))

        _ = hostingController.view
        hostingController.view.layoutIfNeeded()
    }
}
