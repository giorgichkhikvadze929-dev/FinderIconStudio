import FinderIconStudioCore
import SwiftUI

@main
struct FinderIconStudioApp: App {
    @StateObject private var model = StudioModel()

    init() {
        CommandLineMode.runIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 460)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Choose Item...") {
                    model.chooseItem()
                }
                .keyboardShortcut("o")
            }
        }
    }
}
