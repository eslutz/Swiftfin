//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS) || os(visionOS)
import SwiftUI

#if os(iOS)
extension DeviceType {

    // MARK: - Client Image

    var image: ImageResource {
        switch self {
        case .android:
            .deviceClientAndroid
        case .apple:
            .deviceClientApple
        case .chrome:
            .deviceBrowserChrome
        case .edge:
            .deviceBrowserEdge
        case .edgechromium:
            .deviceBrowserEdgechromium
        case .finamp:
            .deviceClientFinamp
        case .firefox:
            .deviceBrowserFirefox
        case .homeAssistant:
            .deviceOtherHomeassistant
        case .html5:
            .deviceBrowserHtml5
        case .kodi:
            .deviceClientKodi
        case .msie:
            .deviceBrowserMsie
        case .opera:
            .deviceBrowserOpera
        case .playstation:
            .deviceClientPlaystation
        case .roku:
            .deviceClientRoku
        case .safari:
            .deviceBrowserSafari
        case .samsungtv:
            .deviceClientSamsungtv
        case .webos:
            .deviceClientWebos
        case .windows:
            .deviceClientWindows
        case .xbox:
            .deviceClientXbox
        case .other:
            .deviceOtherOther
        }
    }
}

#elseif os(visionOS)
extension DeviceType {

    // Device icon resources currently live in the iOS asset catalog only.
    @available(*, unavailable, message: "Device icon resources are only included in the iOS target.")
    var image: ImageResource {
        fatalError()
    }
}
#endif
#endif
