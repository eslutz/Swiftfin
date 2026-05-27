//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Defaults
import Foundation
@preconcurrency import JellyfinAPI
import Logging
import SwiftUI

// TODO: After NativeVideoPlayer is removed, can move bindings and
//       observers to AVPlayerView, like the VLC delegate
//       - wouldn't need to have MediaPlayerProxy: MediaPlayerObserver
// TODO: report playback information, see VLCUI.PlaybackInformation (dropped frames, etc.)
// TODO: report buffering state
// TODO: have set seconds with completion handler

@MainActor
class AVMediaPlayerProxy: VideoMediaPlayerProxy {

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    var isScrubbing: Binding<Bool> = .constant(false)
    var scrubbedSeconds: Binding<Duration> = .constant(.zero)
    var videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)

    let avPlayerLayer: AVPlayerLayer
    let player: AVPlayer

//    private var rateObserver: NSKeyValueObservation!
    private var itemDidPlayToEndObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation!
    private var timeControlStatusObserver: NSKeyValueObservation!
    private var timeObserver: Any!
    private var managerItemObserver: AnyCancellable?
    private var managerStateObserver: AnyCancellable?

    #if os(visionOS)
    private let logger = Logger.swiftfin()
    #endif

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }

            if let manager {
                managerItemObserver = manager.$playbackItem
                    .sink { playbackItem in
                        if let playbackItem {
                            self.playNew(item: playbackItem)
                        }
                    }

                managerStateObserver = manager.$state
                    .sink { state in
                        switch state {
                        case .stopped:
                            self.playbackStopped()
                        default: break
                        }
                    }
            } else {
                managerItemObserver?.cancel()
                managerStateObserver?.cancel()
            }
        }
    }

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    init() {
        self.player = AVPlayer()
        self.avPlayerLayer = AVPlayerLayer(player: player)

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] newTime in
            let seconds = newTime.seconds

            Task { @MainActor [weak self] in
                guard let self else { return }

                let newSeconds = Duration.seconds(seconds)

                if !self.isScrubbing.wrappedValue {
                    self.scrubbedSeconds.wrappedValue = newSeconds
                }

                self.manager?.seconds = newSeconds
            }
        }
    }

    deinit {
        if let itemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(itemDidPlayToEndObserver)
        }
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func jumpForward(_ seconds: Duration) {
        let currentTime = player.currentTime()
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        let currentTime = player.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 1))
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setSeconds(_ seconds: Duration) {
        let time = CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // TODO: complete
    func setRate(_ rate: Float) {}
    func setAudioStream(_ stream: MediaStream) {}
    func setSubtitleStream(_ stream: MediaStream) {}

    func setAspectFill(_ aspectFill: Bool) {
        avPlayerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
    }

    var videoPlayerBody: some View {
        AVPlayerView()
            .environmentObject(self)
    }
}

extension AVMediaPlayerProxy {

    private func playbackStopped() {
        player.pause()
        removeItemDidPlayToEndObserver()

        if let timeObserver {
            DispatchQueue.main.async {
                self.player.removeTimeObserver(timeObserver)
                self.timeObserver = nil
            }
        }

        if let statusObserver {
            statusObserver.invalidate()
            self.statusObserver = nil
        }

        if let timeControlStatusObserver {
            timeControlStatusObserver.invalidate()
            self.timeControlStatusObserver = nil
        }
    }

    private func observeItemDidPlayToEnd(_ item: AVPlayerItem) {
        removeItemDidPlayToEndObserver()

        itemDidPlayToEndObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self, weak item] _ in
            Task { @MainActor [weak self, weak item] in
                guard let self, let item else { return }
                guard self.player.currentItem === item else { return }
                guard self.manager?.item.isLiveStream != true else { return }

                self.removeItemDidPlayToEndObserver()

                if let runtime = self.manager?.item.runtime {
                    self.manager?.seconds = runtime
                }

                self.manager?.ended()
            }
        }
    }

    private func removeItemDidPlayToEndObserver() {
        guard let itemDidPlayToEndObserver else { return }

        NotificationCenter.default.removeObserver(itemDidPlayToEndObserver)
        self.itemDidPlayToEndObserver = nil
    }

    private func playNew(item: MediaPlayerItem) {
        let baseItem = item.baseItem

        #if os(visionOS)
        let visionItemID = baseItem.id ?? "Unknown"
        let visionItemTitle = baseItem.displayTitle
        #endif

        let newAVPlayerItem = AVPlayerItem(url: item.url)
        newAVPlayerItem.externalMetadata = item.baseItem.avMetadata

        player.replaceCurrentItem(with: newAVPlayerItem)
        observeItemDidPlayToEnd(newAVPlayerItem)

        #if os(visionOS)
        logger.debug(
            "visionOS AVPlayer item replaced",
            metadata: visionLogMetadata(
                itemID: visionItemID,
                itemTitle: visionItemTitle
            )
        )
        #endif

        // TODO: protect against paused
//        rateObserver = player.observe(\.rate, options: [.new, .initial]) { _, value in
//            DispatchQueue.main.async {
//                self.manager?.set(rate: value.newValue ?? 1.0)
//            }
//        }

        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { player, _ in
            let timeControlStatus = player.timeControlStatus

            Task { @MainActor [weak self] in
                guard let self else { return }

                switch timeControlStatus {
                case .paused:
                    self.manager?.setPlaybackRequestStatus(status: .paused)
                case .waitingToPlayAtSpecifiedRate:
                    #if os(visionOS)
                    self.logger.warning(
                        "visionOS AVPlayer waiting to play",
                        metadata: self.visionLogMetadata(
                            itemID: visionItemID,
                            itemTitle: visionItemTitle,
                            status: self.visionTimeControlStatusDescription(timeControlStatus)
                        )
                    )
                    #endif
                // TODO: buffering
                case .playing:
                    self.manager?.setPlaybackRequestStatus(status: .playing)
                @unknown default: ()
                }
            }
        }

        // TODO: proper handling of none/unknown states
        statusObserver = player.observe(\.currentItem?.status, options: [.new, .initial]) { _, value in
            guard let newValue = value.newValue else { return }
            switch newValue {
            case .failed:
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    guard let error = self.player.error else {
                        #if os(visionOS)
                        self.logger.warning(
                            "visionOS AVPlayer failed without an error",
                            metadata: self.visionLogMetadata(
                                itemID: visionItemID,
                                itemTitle: visionItemTitle,
                                status: self.visionPlayerItemStatusDescription(newValue)
                            )
                        )
                        #endif

                        return
                    }

                    #if os(visionOS)
                    self.logger.error(
                        "visionOS AVPlayer failed",
                        metadata: self.visionLogMetadata(
                            itemID: visionItemID,
                            itemTitle: visionItemTitle,
                            status: self.visionPlayerItemStatusDescription(newValue),
                            error: error.localizedDescription
                        )
                    )
                    #endif

                    self.manager?.error(ErrorMessage("AVPlayer error: \(error.localizedDescription)"))
                }
            case .none, .readyToPlay, .unknown:
                let startSeconds = max(.zero, (baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset]))

                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if newValue == .readyToPlay {
                        #if os(visionOS)
                        self.logger.debug(
                            "visionOS AVPlayer ready; seeking to start position",
                            metadata: self.visionLogMetadata(
                                itemID: visionItemID,
                                itemTitle: visionItemTitle,
                                status: self.visionPlayerItemStatusDescription(newValue)
                            )
                        )
                        #endif
                    }

                    self.player.seek(
                        to: CMTimeMake(
                            value: startSeconds.components.seconds,
                            timescale: 1
                        ),
                        toleranceBefore: .zero,
                        toleranceAfter: .zero,
                        completionHandler: { [weak self] _ in
                            Task { @MainActor [weak self] in
                                self?.play()
                            }
                        }
                    )
                }
            @unknown default: ()
            }
        }
    }
}

#if os(visionOS)
private extension AVMediaPlayerProxy {

    func visionLogMetadata(
        itemID: String,
        itemTitle: String,
        status: String? = nil,
        error: String? = nil
    ) -> Logger.Metadata {
        var metadata: Logger.Metadata = [
            "platform": .string("visionOS"),
            "player": .string("native-avkit"),
            "itemID": .stringConvertible(itemID),
            "itemTitle": .stringConvertible(itemTitle),
        ]

        if let status {
            metadata["status"] = .string(status)
        }

        if let error {
            metadata["error"] = .string(error)
        }

        return metadata
    }

    func visionPlayerItemStatusDescription(_ status: AVPlayerItem.Status?) -> String {
        switch status {
        case .none:
            "none"
        case .some(.failed):
            "failed"
        case .some(.readyToPlay):
            "readyToPlay"
        case .some(.unknown):
            "unknown"
        @unknown default:
            "unknown"
        }
    }

    func visionTimeControlStatusDescription(_ status: AVPlayer.TimeControlStatus) -> String {
        switch status {
        case .paused:
            "paused"
        case .waitingToPlayAtSpecifiedRate:
            "waitingToPlayAtSpecifiedRate"
        case .playing:
            "playing"
        @unknown default:
            "unknown"
        }
    }
}
#endif

// MARK: - AVPlayerView

extension AVMediaPlayerProxy {

    struct AVPlayerView: UIViewRepresentable {

        @EnvironmentObject
        private var proxy: AVMediaPlayerProxy
        @EnvironmentObject
        private var scrubbedSeconds: PublishedBox<Duration>

        func makeUIView(context: Context) -> UIView {
//            proxy.isScrubbing = context.environment.isScrubbing
//            proxy.scrubbedSeconds = $scrubbedSeconds.value
            UIAVPlayerView(proxy: proxy)
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    private class UIAVPlayerView: UIView {

        let proxy: AVMediaPlayerProxy

        init(proxy: AVMediaPlayerProxy) {
            self.proxy = proxy
            super.init(frame: .zero)
            layer.addSublayer(proxy.avPlayerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            proxy.avPlayerLayer.frame = bounds
        }
    }
}
