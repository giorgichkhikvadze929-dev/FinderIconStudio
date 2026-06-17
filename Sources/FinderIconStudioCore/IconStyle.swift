import AppKit
import Foundation

public enum IconTreatment: String, Codable, CaseIterable, Identifiable, Sendable {
    case original
    case color
    case photo

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .original: "Original"
        case .color: "Color"
        case .photo: "Photo"
        }
    }
}

public struct CodableColor: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var nsColor: NSColor {
        NSColor(
            calibratedRed: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }

    public static let macBlue = CodableColor(red: 0.16, green: 0.48, blue: 0.95)
}

public struct IconStyle: Codable, Equatable, Identifiable, Sendable {
    public var id: URL { itemURL }
    public var itemURL: URL
    public var treatment: IconTreatment
    public var color: CodableColor
    public var photoURL: URL?
    public var hidesLabel: Bool
    public var updatedAt: Date

    public init(
        itemURL: URL,
        treatment: IconTreatment = .original,
        color: CodableColor = .macBlue,
        photoURL: URL? = nil,
        hidesLabel: Bool = false,
        updatedAt: Date = .now
    ) {
        self.itemURL = itemURL
        self.treatment = treatment
        self.color = color
        self.photoURL = photoURL
        self.hidesLabel = hidesLabel
        self.updatedAt = updatedAt
    }
}
