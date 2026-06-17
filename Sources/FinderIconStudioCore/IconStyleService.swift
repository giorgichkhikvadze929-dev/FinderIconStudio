import AppKit
import Foundation

public final class IconStyleService: @unchecked Sendable {
    public static let shared = IconStyleService()

    private let store: StyleStore

    public init(store: StyleStore = .shared) {
        self.store = store
    }

    public func style(for itemURL: URL) -> IconStyle {
        store.style(for: itemURL) ?? IconStyle(itemURL: itemURL)
    }

    public func recentStyles() -> [IconStyle] {
        _ = try? store.removeMissingItems()
        return store.styles()
    }

    public func apply(_ style: IconStyle) throws {
        var style = style
        style.updatedAt = .now

        if style.treatment == .original {
            try restoreOriginalIcon(for: style.itemURL)
            return
        }

        let icon = try IconRenderer.render(style: style)
        guard NSWorkspace.shared.setIcon(icon, forFile: style.itemURL.path, options: []) else {
            throw IconStudioError.failedToApplyIcon
        }

        try store.save(style)
    }

    public func applyColor(_ color: CodableColor, to itemURL: URL) throws {
        var style = self.style(for: itemURL)
        style.treatment = .color
        style.color = color
        _ = NSWorkspace.shared.setIcon(nil, forFile: itemURL.path, options: [])
        try apply(style)
    }

    public func applyPhoto(_ photoURL: URL, to itemURL: URL) throws {
        var style = self.style(for: itemURL)
        style.treatment = .photo
        style.photoURL = photoURL
        try apply(style)
    }

    public func setLabelHidden(_ hidden: Bool, for itemURL: URL) throws {
        var style = self.style(for: itemURL)
        style.hidesLabel = hidden
        style.updatedAt = .now
        try store.save(style)
    }

    public func restoreOriginalIcon(for itemURL: URL) throws {
        guard FileManager.default.fileExists(atPath: itemURL.path) else {
            try store.remove(itemURL: itemURL)
            return
        }

        guard NSWorkspace.shared.setIcon(nil, forFile: itemURL.path, options: []) else {
            throw IconStudioError.failedToApplyIcon
        }
        try store.remove(itemURL: itemURL)
    }
}
