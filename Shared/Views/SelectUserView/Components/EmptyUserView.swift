//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct EmptyUserView: View {

        let action: () -> Void

        private let columns: CGFloat = UIDevice.isPhone ? 2 : 5

        private var imageSystemName: String {
            #if os(visionOS)
            "person.crop.circle.badge.plus"
            #else
            "plus"
            #endif
        }

        @ViewBuilder
        private var imageView: some View {
            RelativeSystemImageView(systemName: imageSystemName)
            #if os(visionOS)
                .padding(24)
            #endif
                .foregroundStyle(Color.secondary)
                .background(.thinMaterial)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.circle)
                .posterShadow()
        }

        @ViewBuilder
        private var addUserButton: some View {
            Button(action: action) {
                #if os(tvOS)
                imageView
                    .hoverEffect(.highlight)

                Text(L10n.addUser)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                #elseif os(visionOS)
                VStack(spacing: 8) {
                    imageView
                        .frame(width: 120, height: 120)

                    Text(L10n.addUser)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 18))
                #else
                VStack {
                    imageView

                    Text(L10n.addUser)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                #endif
            }
            .foregroundStyle(.primary, .secondary)
            #if os(tvOS)
                .buttonStyle(.borderless)
                .backport
                .buttonBorderShape(.circle)
            #elseif os(visionOS)
                .buttonStyle(.plain)
                .visionHoverEffect(RoundedRectangle(cornerRadius: 18, style: .continuous))
            #endif
        }

        var body: some View {
            GeometryReader { geometry in
                addUserButton
                    .frame(maxWidth: (geometry.size.width - EdgeInsets.edgePadding * (columns + 1)) / columns)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusSection()
            }
        }
    }
}
