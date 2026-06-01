//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A tappable poster for any `Poster` item, sized for visionOS with a system
/// hover effect. Routing is supplied by the caller so the button stays reusable.
struct PosterButton<Item: Poster>: View {

    let item: Item
    var landscape: Bool = false
    let action: (Item) -> Void

    private var width: CGFloat {
        landscape ? 280 : 140
    }

    private var height: CGFloat {
        landscape ? 157 : 210
    }

    private var imageSources: [ImageSource] {
        landscape
            ? item.landscapeImageSources(maxWidth: width)
            : item.portraitImageSources(maxWidth: width)
    }

    var body: some View {
        Button {
            action(item)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ImageView(imageSources)
                    .failure {
                        Image(systemName: item.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.regularMaterial)
                    }
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .hoverEffect()

                Text(item.displayTitle)
                    .font(.subheadline)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
