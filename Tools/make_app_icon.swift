import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsURL = root.appendingPathComponent("Assets", isDirectory: true)
let outputURL = assetsURL.appendingPathComponent("finder-icon-studio-source.png")
let iconsetURL = assetsURL.appendingPathComponent("FinderIconStudio.iconset", isDirectory: true)

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

image.lockFocus()

let canvas = NSRect(origin: .zero, size: size)
NSColor.clear.setFill()
canvas.fill()

let background = roundedRect(NSRect(x: 42, y: 42, width: 940, height: 940), radius: 210)
NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.14, blue: 0.19, alpha: 1),
    NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.10, alpha: 1)
])?.draw(in: background, angle: -90)

let bgStroke = roundedRect(NSRect(x: 58, y: 58, width: 908, height: 908), radius: 194)
NSColor.white.withAlphaComponent(0.08).setStroke()
bgStroke.lineWidth = 4
bgStroke.stroke()

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
shadow.shadowOffset = NSSize(width: 0, height: -24)
shadow.shadowBlurRadius = 36
shadow.set()

let tab = roundedRect(NSRect(x: 174, y: 682, width: 292, height: 130), radius: 42)
NSGradient(colors: [
    NSColor(calibratedRed: 0.48, green: 0.82, blue: 1.0, alpha: 1),
    NSColor(calibratedRed: 0.11, green: 0.54, blue: 0.95, alpha: 1)
])?.draw(in: tab, angle: -90)

let folder = roundedRect(NSRect(x: 150, y: 256, width: 724, height: 500), radius: 58)
NSGradient(colors: [
    NSColor(calibratedRed: 0.44, green: 0.82, blue: 1.0, alpha: 1),
    NSColor(calibratedRed: 0.05, green: 0.48, blue: 0.95, alpha: 1)
])?.draw(in: folder, angle: -90)

NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0)

let folderHighlight = roundedRect(NSRect(x: 178, y: 292, width: 668, height: 430), radius: 44)
NSColor.white.withAlphaComponent(0.28).setStroke()
folderHighlight.lineWidth = 8
folderHighlight.stroke()

let sparkleLarge = NSBezierPath()
sparkleLarge.move(to: NSPoint(x: 676, y: 640))
sparkleLarge.curve(to: NSPoint(x: 718, y: 598), controlPoint1: NSPoint(x: 688, y: 618), controlPoint2: NSPoint(x: 696, y: 610))
sparkleLarge.curve(to: NSPoint(x: 676, y: 556), controlPoint1: NSPoint(x: 696, y: 586), controlPoint2: NSPoint(x: 688, y: 578))
sparkleLarge.curve(to: NSPoint(x: 634, y: 598), controlPoint1: NSPoint(x: 664, y: 578), controlPoint2: NSPoint(x: 656, y: 586))
sparkleLarge.curve(to: NSPoint(x: 676, y: 640), controlPoint1: NSPoint(x: 656, y: 610), controlPoint2: NSPoint(x: 664, y: 618))
sparkleLarge.close()
NSColor.white.withAlphaComponent(0.96).setFill()
sparkleLarge.fill()

let wheelCenter = NSPoint(x: 714, y: 326)
let wheelRadius: CGFloat = 146
let segmentColors: [NSColor] = [
    .systemRed, .systemOrange, .systemYellow, .systemGreen,
    .systemTeal, .systemBlue, .systemPurple, .systemPink
]

for index in segmentColors.indices {
    let start = CGFloat(index) * 45 - 90
    let end = start + 45
    let path = NSBezierPath()
    path.move(to: wheelCenter)
    path.appendArc(withCenter: wheelCenter, radius: wheelRadius, startAngle: start, endAngle: end)
    path.close()
    segmentColors[index].setFill()
    path.fill()
}

NSColor.white.setStroke()
NSBezierPath(ovalIn: NSRect(x: wheelCenter.x - wheelRadius, y: wheelCenter.y - wheelRadius, width: wheelRadius * 2, height: wheelRadius * 2)).lineWidth = 20
NSBezierPath(ovalIn: NSRect(x: wheelCenter.x - wheelRadius, y: wheelCenter.y - wheelRadius, width: wheelRadius * 2, height: wheelRadius * 2)).stroke()

NSGradient(colors: [.white, NSColor(calibratedWhite: 0.82, alpha: 1)])?.draw(in: NSBezierPath(ovalIn: NSRect(x: wheelCenter.x - 50, y: wheelCenter.y - 50, width: 100, height: 100)), angle: -90)

image.unlockFocus()

guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not render PNG")
}

try png.write(to: outputURL)

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for icon in sizes {
    let resized = NSImage(size: NSSize(width: icon.pixels, height: icon.pixels))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: icon.pixels, height: icon.pixels), from: canvas, operation: .sourceOver, fraction: 1)
    resized.unlockFocus()

    guard let tiff = resized.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let data = rep.representation(using: .png, properties: [:]) else {
        continue
    }

    try data.write(to: iconsetURL.appendingPathComponent(icon.name))
}
