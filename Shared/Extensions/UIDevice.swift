//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension UIDevice {

    static var vendorUUIDString: String {
        current.identifierForVendor!.uuidString
    }

    static var isPad: Bool {
        #if os(visionOS)
        // Reuse the iPad layout path until visionOS has dedicated spatial layouts.
        true
        #else
        current.userInterfaceIdiom == .pad
        #endif
    }

    static var isPhone: Bool {
        #if os(visionOS)
        false
        #else
        current.userInterfaceIdiom == .phone
        #endif
    }

    static var isTV: Bool {
        #if os(visionOS)
        false
        #else
        current.userInterfaceIdiom == .tv
        #endif
    }

    static var isVision: Bool {
        #if os(visionOS)
        true
        #else
        false
        #endif
    }

    static var hasNotch: Bool {
        #if os(visionOS)
        false
        #else
        (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0) > 0 &&
            isPhone
        #endif
    }

    static var platform: String {
        #if os(visionOS)
        L10n.visionOS
        #elseif os(tvOS)
        L10n.tvOS
        #else
        if UIDevice.isPad {
            return L10n.iPadOS
        } else {
            return L10n.iOS
        }
        #endif
    }

    /// - Important: Does nothing on non-iOS platforms.
    static func feedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(type)
        #endif
    }

    // TODO: make more custom feedback types with Core Haptics
    //       - soft with intensity
    /// - Important: Does nothing on non-iOS platforms.
    static func impact(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: type).impactOccurred()
        #endif
    }

    #if os(iOS)
    static var isPortrait: Bool {
        current.orientation.isPortrait
    }

    static var isLandscape: Bool {
        isPad || current.orientation.isLandscape
    }
    #endif
}

#if os(tvOS) || os(visionOS)
enum UINotificationFeedbackGenerator {
    enum FeedbackType {
        case success
        case warning
        case error
    }
}

enum UIImpactFeedbackGenerator {
    enum FeedbackStyle {
        case light
        case medium
        case heavy
    }
}
#endif
