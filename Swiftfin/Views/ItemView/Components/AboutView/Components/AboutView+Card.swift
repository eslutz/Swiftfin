//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.AboutView {

    struct Card<Content: View>: View {

        private let action: (() -> Void)?
        private let content: Content
        private let title: String
        private let subtitle: String?

        private var cardShape: RoundedRectangle {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        }

        init(
            title: String,
            subtitle: String? = nil,
            action: (() -> Void)? = nil,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.title = title
            self.subtitle = subtitle
            self.action = action
            self.content = content()
        }

        @ViewBuilder
        private var cardBackground: some View {
            #if os(visionOS)
            cardShape
                .fill(Color.systemFill)
            #else
            Rectangle()
                .fill(Color.systemFill)
                .cornerRadius(ratio: 1 / 45, of: \.height)
            #endif
        }

        @ViewBuilder
        private var cardContent: some View {
            ZStack(alignment: .leading) {
                cardBackground

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    content
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            #if os(visionOS)
                .clipShape(cardShape)
                .contentShape(cardShape)
                .contentShape(.hoverEffect, cardShape)
                .containerShape(cardShape)
            #endif
        }

        var body: some View {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
                #if os(visionOS)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .visionHoverEffect(cornerRadius: 18)
                #endif
            } else {
                cardContent
            }
        }
    }
}
