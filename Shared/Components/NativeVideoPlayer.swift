//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVKit
import Factory
import JellyfinAPI
import Logging
import SwiftUI
#if !os(visionOS)
import Transmission
#endif

// TODO: remove

struct NativeVideoPlayer: View {

    #if !os(visionOS)
    @Environment(\.presentationCoordinator)
    private var presentationCoordinator
    #endif

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @LazyState
    private var proxy: AVMediaPlayerProxy

    @Router
    private var router

    #if os(visionOS)
    private let logger = Logger.swiftfin()
    #endif

    init() {
        self._proxy = .init(wrappedValue: AVMediaPlayerProxy())
    }

    var body: some View {
        content
            .alert(
                L10n.error,
                isPresented: .constant(manager.error != nil)
            ) {
                Button(L10n.close, role: .cancel) {
                    Container.shared.mediaPlayerManager.reset()
                    router.dismiss()
                }
            } message: {
                Text(L10n.unableToLoadThisItem)
            }
    }

    @ViewBuilder
    private var content: some View {
        let playerView = ZStack {

            Color.black

            switch manager.state {
            case .playback:
                NativeVideoPlayerView(proxy: proxy)
            default:
                ProgressView()
            }
        }
        .onAppear {
            #if os(visionOS)
            logger.info(
                "visionOS native player appeared; starting playback",
                metadata: visionLogMetadata
            )
            #endif

            manager.proxy = proxy
            manager.start()
        }
        .prefersStatusBarHidden()

        #if os(visionOS)
        playerView
            .onDisappear {
                if !isExpectedVisionDisappearState {
                    logger.warning(
                        "visionOS native player disappeared outside playback flow",
                        metadata: visionLogMetadata
                    )
                }

                logger.debug(
                    "visionOS native player disappeared; cleaning up playback",
                    metadata: visionLogMetadata
                )

                Container.shared.mediaPlayerManager.reset()
                manager.stop()
            }
        #else
        playerView
            .backport
            .onChange(of: presentationCoordinator.isPresented) { _, isPresented in
                Container.shared.mediaPlayerManager.reset()
                guard !isPresented else { return }
                manager.stop()
            }
        #endif
    }
}

#if os(visionOS)
private extension NativeVideoPlayer {

    var visionLogMetadata: Logger.Metadata {
        var metadata: Logger.Metadata = [
            "platform": .string("visionOS"),
            "player": .string("native-avkit"),
            "state": .string(String(describing: manager.state)),
        ]

        if let playbackItem = manager.playbackItem {
            metadata["itemID"] = .stringConvertible(playbackItem.baseItem.id ?? "Unknown")
            metadata["itemTitle"] = .stringConvertible(playbackItem.baseItem.displayTitle)
        } else {
            metadata["itemID"] = .stringConvertible(manager.item.id ?? "Unknown")
            metadata["itemTitle"] = .stringConvertible(manager.item.displayTitle)
        }

        return metadata
    }

    var isExpectedVisionDisappearState: Bool {
        manager.state.isExpectedNativeVideoPlayerDisappearState
    }
}

extension MediaPlayerManager._State {

    var isExpectedNativeVideoPlayerDisappearState: Bool {
        switch self {
        case .error, .stopped:
            true
        case .initial, .loadingItem, .playback:
            false
        }
    }
}
#endif

extension NativeVideoPlayer {

    private struct NativeVideoPlayerView: UIViewControllerRepresentable {

        let proxy: AVMediaPlayerProxy

        func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
            UINativeVideoPlayerViewController(proxy: proxy)
        }

        func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
    }

    private class UINativeVideoPlayerViewController: AVPlayerViewController {

        private let proxy: AVMediaPlayerProxy

        init(proxy: AVMediaPlayerProxy) {
            self.proxy = proxy

            super.init(nibName: nil, bundle: nil)

            player = proxy.player

            player?.appliesMediaSelectionCriteriaAutomatically = false
            #if !os(visionOS)
            player?.allowsExternalPlayback = true
            player?.usesExternalPlaybackWhileExternalScreenIsActive = true
            allowsPictureInPicturePlayback = true
            #endif

            #if !os(tvOS) && !os(visionOS)
            updatesNowPlayingInfoCenter = false
            #endif
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
