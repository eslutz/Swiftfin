//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A titled horizontal rail of posters. Hides itself when there are no items.
struct PosterRail<Item: Poster>: View {

    let title: String
    let items: [Item]
    var landscape: Bool = false
    let action: (Item) -> Void

    var body: some View {
        if items.isNotEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal, EdgeInsets.edgePadding)

                VisionHorizontalScroll {
                    ForEach(items, id: \.unwrappedIDHashOrZero) { item in
                        PosterButton(item: item, landscape: landscape, action: action)
                    }
                }
            }
        }
    }
}
