//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct AccentColorSettingsView: View {

    @Default(.userAccentColor)
    private var accentColor

    var body: some View {
        Form(systemImage: "paintpalette.fill") {
            Section(L10n.accentColor) {
                LabeledContent(L10n.hexColor) {
                    HStack {
                        Text(L10n.hexColorValue(accentColor.hexString))
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(accentColor)
                            .frame(width: 34, height: 24)
                    }
                }

                componentSlider(L10n.red, keyPath: \.red)
                componentSlider(L10n.green, keyPath: \.green)
                componentSlider(L10n.blue, keyPath: \.blue)
            }
        }
        .navigationTitle(L10n.accentColor)
    }

    private func componentSlider(_ title: String, keyPath: WritableKeyPath<Color.RGBA, CGFloat>) -> some View {
        LabeledContent {
            HStack {
                Slider(
                    value: Binding(
                        get: {
                            Double(accentColor.rgbaComponents[keyPath: keyPath])
                        },
                        set: { newValue in
                            accentColor = accentColor.with(rgba: keyPath, value: CGFloat(newValue))
                        }
                    ),
                    in: 0 ... 1
                )

                Text(Int(accentColor.rgbaComponents[keyPath: keyPath] * 255), format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }
        } label: {
            Text(title)
        }
    }
}
