import AppKit
import FinderIconStudioCore
import FinderSync

final class FinderSync: FIFinderSync {
    private let service = IconStyleService.shared

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [
            FileManager.default.homeDirectoryForCurrentUser,
            FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0],
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        ]
    }

    override var menu: NSMenu {
        let menu = NSMenu(title: "Finder Icon Studio")
        menu.addItem(NSMenuItem(title: "Add Photo...", action: #selector(addPhoto), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Change Color...", action: #selector(changeColor), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide Label", action: #selector(hideLabel), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Restore Original", action: #selector(restoreOriginal), keyEquivalent: ""))
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func addPhoto() {
        guard let item = selectedItemURL() else { return }

        let panel = NSOpenPanel()
        panel.title = "Choose Photo"
        panel.prompt = "Add"
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let photoURL = panel.url {
            try? service.applyPhoto(photoURL, to: item)
        }
    }

    @objc private func changeColor() {
        guard let item = selectedItemURL() else { return }

        let panel = NSColorPanel.shared
        panel.color = service.style(for: item).color.nsColor
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        guard let item = selectedItemURL() else { return }
        let color = sender.color.usingColorSpace(.deviceRGB) ?? sender.color
        try? service.applyColor(
            CodableColor(
                red: Double(color.redComponent),
                green: Double(color.greenComponent),
                blue: Double(color.blueComponent),
                alpha: Double(color.alphaComponent)
            ),
            to: item
        )
    }

    @objc private func hideLabel() {
        guard let item = selectedItemURL() else { return }
        try? service.setLabelHidden(true, for: item)
    }

    @objc private func restoreOriginal() {
        guard let item = selectedItemURL() else { return }
        try? service.restoreOriginalIcon(for: item)
    }

    private func selectedItemURL() -> URL? {
        FIFinderSyncController.default().selectedItemURLs()?.first
    }
}
