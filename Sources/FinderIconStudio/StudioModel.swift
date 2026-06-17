import AppKit
import FinderIconStudioCore
import SwiftUI

@MainActor
final class StudioModel: ObservableObject {
    @Published var selectedURL: URL?
    @Published var style: IconStyle?
    @Published var recentStyles: [IconStyle] = []
    @Published var lastError: String?

    private let service = IconStyleService.shared

    init() {
        refreshRecent()
    }

    func chooseItem() {
        let panel = NSOpenPanel()
        panel.title = "Choose File or Folder"
        panel.prompt = "Choose"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        select(url)
    }

    func choosePhoto() {
        guard let selectedURL else { return }

        let panel = NSOpenPanel()
        panel.title = "Choose Photo"
        panel.prompt = "Add"
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let photoURL = panel.url else { return }
        perform {
            try service.applyPhoto(photoURL, to: selectedURL)
            select(selectedURL)
        }
    }

    func select(_ url: URL) {
        selectedURL = url
        style = service.style(for: url)
        lastError = nil
        refreshRecent()
    }

    func applyColor(_ color: NSColor) {
        guard let selectedURL else { return }
        let converted = color.usingColorSpace(.deviceRGB) ?? color
        perform {
            try service.applyColor(
                CodableColor(
                    red: Double(converted.redComponent),
                    green: Double(converted.greenComponent),
                    blue: Double(converted.blueComponent),
                    alpha: Double(converted.alphaComponent)
                ),
                to: selectedURL
            )
            select(selectedURL)
        }
    }

    func setLabelHidden(_ hidden: Bool) {
        guard let selectedURL else { return }
        perform {
            try service.setLabelHidden(hidden, for: selectedURL)
            select(selectedURL)
        }
    }

    func restoreOriginal() {
        guard let selectedURL else { return }
        perform {
            try service.restoreOriginalIcon(for: selectedURL)
            select(selectedURL)
        }
    }

    func icon(for url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    private func refreshRecent() {
        recentStyles = service.recentStyles()
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
