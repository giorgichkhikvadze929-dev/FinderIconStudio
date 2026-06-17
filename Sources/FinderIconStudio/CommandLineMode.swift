import AppKit
import FinderIconStudioCore
import Foundation

enum CommandLineMode {
    static func runIfNeeded(arguments: [String] = CommandLine.arguments) {
        guard arguments.count >= 4, arguments[1] == "--apply-color" else { return }

        let itemURL = URL(fileURLWithPath: arguments[2])
        guard let color = CodableColor(hex: arguments[3]) else {
            fputs("Invalid color. Use hex like #34C759.\n", stderr)
            exit(2)
        }

        do {
            try IconStyleService.shared.applyColor(color, to: itemURL)
            exit(0)
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}

private extension CodableColor {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6, let integer = Int(value, radix: 16) else {
            return nil
        }

        self.init(
            red: Double((integer >> 16) & 0xff) / 255,
            green: Double((integer >> 8) & 0xff) / 255,
            blue: Double(integer & 0xff) / 255
        )
    }
}
