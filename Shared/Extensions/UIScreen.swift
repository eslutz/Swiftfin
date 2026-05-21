//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics

#if !os(visionOS)
import UIKit

extension UIScreen {

    func scale(_ x: Int) -> Int {
        Int(nativeScale) * x
    }

    func scale(_ x: CGFloat) -> Int {
        Int(nativeScale * x)
    }
}
#endif

enum PlatformScreen {

    static func scale(_ x: CGFloat) -> Int {
        #if os(visionOS)
        Int(2 * x)
        #else
        UIScreen.main.scale(x)
        #endif
    }
}
