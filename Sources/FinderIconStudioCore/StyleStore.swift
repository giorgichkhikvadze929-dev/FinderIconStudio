import Foundation

public final class StyleStore: @unchecked Sendable {
    public static let shared = StyleStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager: FileManager
    private let storeURL: URL
    private let queue = DispatchQueue(label: "FinderIconStudio.StyleStore")

    public init(
        fileManager: FileManager = .default,
        storeURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.storeURL = storeURL ?? fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Finder Icon Studio", isDirectory: true)
            .appendingPathComponent("styles.json")

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func styles() -> [IconStyle] {
        queue.sync {
            guard let data = try? Data(contentsOf: storeURL) else { return [] }
            return (try? decoder.decode([IconStyle].self, from: data)) ?? []
        }
    }

    public func style(for itemURL: URL) -> IconStyle? {
        styles().first { $0.itemURL.standardizedFileURL == itemURL.standardizedFileURL }
    }

    public func save(_ style: IconStyle) throws {
        try queue.sync {
            var current = stylesWithoutLock()
            current.removeAll { $0.itemURL.standardizedFileURL == style.itemURL.standardizedFileURL }
            current.insert(style, at: 0)
            try writeWithoutLock(current)
        }
    }

    public func remove(itemURL: URL) throws {
        try queue.sync {
            var current = stylesWithoutLock()
            current.removeAll { $0.itemURL.standardizedFileURL == itemURL.standardizedFileURL }
            try writeWithoutLock(current)
        }
    }

    @discardableResult
    public func removeMissingItems() throws -> Int {
        try queue.sync {
            let current = stylesWithoutLock()
            let existing = current.filter { fileManager.fileExists(atPath: $0.itemURL.path) }
            let removedCount = current.count - existing.count

            if removedCount > 0 {
                try writeWithoutLock(existing)
            }

            return removedCount
        }
    }

    private func stylesWithoutLock() -> [IconStyle] {
        guard let data = try? Data(contentsOf: storeURL) else { return [] }
        return (try? decoder.decode([IconStyle].self, from: data)) ?? []
    }

    private func writeWithoutLock(_ styles: [IconStyle]) throws {
        try fileManager.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(styles)
        try data.write(to: storeURL, options: [.atomic])
    }
}
