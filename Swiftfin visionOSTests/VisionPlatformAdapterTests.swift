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

/// Exercises the visionOS platform adapters that replace the UIKit-backed
/// CollectionHStack / CollectionVGrid: the native ScrollView + Lazy* fallbacks
/// and the no-op platform modifiers shared views rely on.
@Suite("visionOS platform adapters")
@MainActor
struct VisionPlatformAdapterTests {

    @Test
    func `horizontal scroll renders its content`() {
        renderToCompletion(
            VisionHorizontalScroll {
                Text("a")
                Text("b")
            }
        )
    }

    @Test
    func `vertical grid renders its items`() {
        renderToCompletion(
            VisionVGrid(
                [1, 2, 3],
                id: \.self,
                columns: [GridItem(.adaptive(minimum: 100))],
                spacing: 8,
                padding: EdgeInsets(),
                onReachedEnd: {}
            ) { item in
                Text(item.description)
            }
        )
    }

    @Test
    func `no-op platform modifiers return a usable view`() {
        renderToCompletion(
            Text("x")
                .focusSection()
                .prefersStatusBarHidden()
                .listRowCornerRadius(8)
        )
    }

    private func renderToCompletion(_ view: some View) {
        let host = UIHostingController(rootView: view)
        _ = host.view
        host.view.layoutIfNeeded()
    }
}
