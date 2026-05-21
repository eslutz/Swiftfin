//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    /// - Important: This does nothing on visionOS.
    func detectOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func focusSection() -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func navigationBarOffset(_ scrollViewOffset: Binding<CGFloat>, start: CGFloat, end: CGFloat) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func navigationBarDrawer(@ViewBuilder _ drawer: @escaping () -> some View) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func navigationBarFilterDrawer(
        viewModel: FilterViewModel,
        types: [ItemFilterType]
    ) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func prefersStatusBarHidden(_ hidden: Bool = true) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func navigationBarCloseButton(
        disabled: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        self
    }

    /// - Important: This does nothing on visionOS.
    func navigationBarMenuButton(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ViewBuilder
        _ items: @escaping () -> some View
    ) -> some View {
        self
    }

    func listRowCornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
