//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import SwiftUI

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
#endif
