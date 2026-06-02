//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import RealityKit
import SwiftUI

/// The Jellyfin brand palette used by the immersive cinema. Mirrors the
/// Jellyfin gradient (`#AC5CC3` → `#00A4DC`) over the brand's dark backdrop.
enum CinemaPalette {

    static let navy = UIColor(red: 0x00 / 255.0, green: 0x0B / 255.0, blue: 0x25 / 255.0, alpha: 1) // #000B25
    static let deep = UIColor(red: 0x10 / 255.0, green: 0x10 / 255.0, blue: 0x10 / 255.0, alpha: 1) // #101010
    static let purple = UIColor(red: 0xAC / 255.0, green: 0x5C / 255.0, blue: 0xC3 / 255.0, alpha: 1) // #AC5CC3
    static let blue = UIColor(red: 0x00 / 255.0, green: 0xA4 / 255.0, blue: 0xDC / 255.0, alpha: 1) // #00A4DC
}

/// A subtle, purpose-built Jellyfin media-room for visionOS playback: a large
/// inward-facing sphere fills the surroundings with the brand's dark backdrop so
/// the native AVKit player reads cleanly without distraction, lit by a soft
/// brand-tinted key light for gentle depth.
struct JellyfinCinemaImmersiveView: View {

    var body: some View {
        RealityView { content in
            content.add(Self.makeRoom())
        }
    }

    @MainActor
    private static func makeRoom() -> Entity {
        let room = Entity()

        // Branded backdrop: a large sphere viewed from the inside.
        let backdrop = ModelEntity(
            mesh: .generateSphere(radius: 12),
            materials: [backdropMaterial()]
        )
        backdrop.scale = SIMD3<Float>(-1, 1, 1)
        room.addChild(backdrop)

        // Soft brand-tinted key light for gentle, comfortable depth.
        let key = Entity()
        key.components.set(
            PointLightComponent(color: CinemaPalette.blue, intensity: 1200)
        )
        key.position = SIMD3<Float>(0, 2.5, -5)
        room.addChild(key)

        let fill = Entity()
        fill.components.set(
            PointLightComponent(color: CinemaPalette.purple, intensity: 600)
        )
        fill.position = SIMD3<Float>(-3, 1, -4)
        room.addChild(fill)

        return room
    }

    private static func backdropMaterial() -> UnlitMaterial {
        var material = UnlitMaterial(color: CinemaPalette.navy)
        if let texture = gradientTexture() {
            material.color = .init(tint: .white, texture: .init(texture))
        }
        return material
    }

    /// A vertical brand gradient (deep → navy → deep) so the room reads as a
    /// soft dome rather than a flat fill. Falls back to a solid navy on failure.
    private static func gradientTexture() -> TextureResource? {
        let size = CGSize(width: 8, height: 512)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = [
                CinemaPalette.deep.cgColor,
                CinemaPalette.navy.cgColor,
                CinemaPalette.deep.cgColor,
            ] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 0.5, 1]
            ) else { return }
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        guard let cgImage = image.cgImage else { return nil }
        return try? TextureResource(image: cgImage, options: .init(semantic: .color))
    }
}
