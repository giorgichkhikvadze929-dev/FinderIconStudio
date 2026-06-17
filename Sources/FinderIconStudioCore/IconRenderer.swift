import AppKit
import Foundation
import UniformTypeIdentifiers

public enum IconRenderer {
    public static func render(style: IconStyle, size: CGFloat = 512) throws -> NSImage {
        switch style.treatment {
        case .original:
            return NSWorkspace.shared.icon(forFile: style.itemURL.path)
        case .color:
            return renderColorIcon(style: style, size: size)
        case .photo:
            return try renderPhotoIcon(style: style, size: size)
        }
    }

    private static func renderColorIcon(style: IconStyle, size: CGFloat) -> NSImage {
        pixelRecoloredIconSet(
            base: defaultIcon(for: style.itemURL, size: size),
            color: style.color.nsColor,
            size: size
        )
    }

    private static func defaultIcon(for itemURL: URL, size: CGFloat) -> NSImage {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: itemURL.path, isDirectory: &isDirectory), isDirectory.boolValue, itemURL.pathExtension != "app" {
            return iconsetFolderIcon(size: size)
        }

        return nativeIcon(for: itemURL, size: size)
    }

    private static func nativeIcon(for itemURL: URL, size: CGFloat) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: itemURL.path)
        icon.size = NSSize(width: size, height: size)
        return icon
    }

    private static func iconsetFolderIcon(size: CGFloat) -> NSImage {
        let path = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns"
        let image = NSImage(size: NSSize(width: size, height: size))

        if let source = NSImage(contentsOfFile: path) {
            for representation in source.representations {
                guard representation.size.width <= 128, representation.size.height <= 128 else { continue }
                image.addRepresentation(representation)
            }
        }

        if image.representations.isEmpty {
            let fallback = NSWorkspace.shared.icon(for: UTType.folder)
            fallback.size = NSSize(width: size, height: size)
            return fallback
        }

        return image
    }

    private static func pixelRecoloredIconSet(base: NSImage, color: NSColor, size: CGFloat) -> NSImage {
        let output = NSImage(size: NSSize(width: size, height: size))
        let target = color.usingColorSpace(.deviceRGB) ?? color
        let targetHSL = rgbToHSL(
            red: Double(target.redComponent),
            green: Double(target.greenComponent),
            blue: Double(target.blueComponent)
        )

        for representation in base.representations {
            guard let bitmap = representation as? NSBitmapImageRep else { continue }
            guard let rep = pixelRecoloredBitmap(bitmap: bitmap, targetHue: targetHSL.hue) else { continue }
            output.addRepresentation(rep)
        }

        if output.representations.isEmpty, let rep = pixelRecoloredBitmap(base: base, targetHue: targetHSL.hue, pixelSize: Int(size.rounded())) {
            output.addRepresentation(rep)
        }

        return output.representations.isEmpty ? base : output
    }

    private static func pixelRecoloredBitmap(bitmap: NSBitmapImageRep, targetHue: Double) -> NSBitmapImageRep? {
        guard let source = bitmap.cgImage else { return nil }
        guard let rep = pixelRecoloredBitmap(source: source, targetHue: targetHue) else { return nil }
        rep.size = bitmap.size
        return rep
    }

    private static func pixelRecoloredBitmap(base: NSImage, targetHue: Double, pixelSize: Int) -> NSBitmapImageRep? {
        let pixelSize = max(1, pixelSize)
        var rect = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
        guard let source = base.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return nil
        }

        return pixelRecoloredBitmap(source: source, targetHue: targetHue)
    }

    private static func pixelRecoloredBitmap(source: CGImage, targetHue: Double) -> NSBitmapImageRep? {
        let width = max(1, source.width)
        let height = max(1, source.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        context.flush()

        for index in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha > 0 else { continue }

            let red = min(1, Double(pixels[index]) / 255 / alpha)
            let green = min(1, Double(pixels[index + 1]) / 255 / alpha)
            let blue = min(1, Double(pixels[index + 2]) / 255 / alpha)
            let hsl = rgbToHSL(red: red, green: green, blue: blue)
            guard shouldRecolorFolderPixel(hsl: hsl) else { continue }

            let recolored = hslToRGB(hue: targetHue, saturation: hsl.saturation, lightness: hsl.lightness)

            pixels[index] = UInt8((recolored.red * alpha * 255).rounded().clamped(to: 0...255))
            pixels[index + 1] = UInt8((recolored.green * alpha * 255).rounded().clamped(to: 0...255))
            pixels[index + 2] = UInt8((recolored.blue * alpha * 255).rounded().clamped(to: 0...255))
        }

        guard let output = context.makeImage() else { return nil }

        let rep = NSBitmapImageRep(cgImage: output)
        rep.size = NSSize(width: source.width, height: source.height)
        return rep
    }

    private static func shouldRecolorFolderPixel(hsl: (hue: Double, saturation: Double, lightness: Double)) -> Bool {
        // Keep original alpha, white highlights, gray edges, and shadows intact.
        // Only the saturated blue folder surface pixels become the chosen color.
        guard hsl.saturation > 0.14 else { return false }
        guard hsl.lightness > 0.18, hsl.lightness < 0.9 else { return false }

        let blueHueRange = 0.47...0.64
        return blueHueRange.contains(hsl.hue)
    }

    private static func rgbToHSL(red: Double, green: Double, blue: Double) -> (hue: Double, saturation: Double, lightness: Double) {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let lightness = (maximum + minimum) / 2

        guard maximum != minimum else {
            return (0, 0, lightness)
        }

        let delta = maximum - minimum
        let saturation = lightness > 0.5 ? delta / (2 - maximum - minimum) : delta / (maximum + minimum)
        let hue: Double

        if maximum == red {
            hue = ((green - blue) / delta + (green < blue ? 6 : 0)) / 6
        } else if maximum == green {
            hue = ((blue - red) / delta + 2) / 6
        } else {
            hue = ((red - green) / delta + 4) / 6
        }

        return (hue, saturation, lightness)
    }

    private static func hslToRGB(hue: Double, saturation: Double, lightness: Double) -> (red: Double, green: Double, blue: Double) {
        guard saturation > 0 else {
            return (lightness, lightness, lightness)
        }

        let q = lightness < 0.5 ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation
        let p = 2 * lightness - q

        return (
            hueToRGB(p: p, q: q, t: hue + 1.0 / 3.0),
            hueToRGB(p: p, q: q, t: hue),
            hueToRGB(p: p, q: q, t: hue - 1.0 / 3.0)
        )
    }

    private static func hueToRGB(p: Double, q: Double, t: Double) -> Double {
        var t = t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        if t < 1.0 / 6.0 { return p + (q - p) * 6 * t }
        if t < 1.0 / 2.0 { return q }
        if t < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - t) * 6 }
        return p
    }

    private static func renderPhotoIcon(style: IconStyle, size: CGFloat) throws -> NSImage {
        guard let photoURL = style.photoURL, let source = NSImage(contentsOf: photoURL) else {
            throw IconStudioError.photoCouldNotBeLoaded
        }

        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()

        let rect = NSRect(x: size * 0.08, y: size * 0.08, width: size * 0.84, height: size * 0.84)
        let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.09, yRadius: size * 0.09)
        NSGraphicsContext.current?.saveGraphicsState()
        path.addClip()

        let sourceSize = source.size
        let sourceAspect = sourceSize.width / max(sourceSize.height, 1)
        let targetAspect = rect.width / rect.height
        let drawRect: NSRect

        if sourceAspect > targetAspect {
            let width = rect.height * sourceAspect
            drawRect = NSRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height)
        } else {
            let height = rect.width / sourceAspect
            drawRect = NSRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height)
        }

        source.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)

        NSGraphicsContext.current?.restoreGraphicsState()
        NSColor.black.withAlphaComponent(0.16).setStroke()
        path.lineWidth = size * 0.018
        path.stroke()

        return image
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

public enum IconStudioError: LocalizedError {
    case photoCouldNotBeLoaded
    case failedToApplyIcon

    public var errorDescription: String? {
        switch self {
        case .photoCouldNotBeLoaded:
            "The selected photo could not be loaded."
        case .failedToApplyIcon:
            "macOS could not apply the custom icon to this item."
        }
    }
}
