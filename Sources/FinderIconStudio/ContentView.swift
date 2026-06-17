import AppKit
import FinderIconStudioCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            DetailView()
        }
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        List(selection: Binding(get: {
            model.selectedURL
        }, set: { url in
            if let url {
                model.select(url)
            }
        })) {
            Section("Item") {
                Button {
                    model.chooseItem()
                } label: {
                    Label("Choose File or Folder", systemImage: "plus")
                }
            }

            Section("Recent") {
                ForEach(model.recentStyles) { style in
                    Label {
                        Text(style.itemURL.lastPathComponent)
                            .lineLimit(1)
                    } icon: {
                        Image(nsImage: model.icon(for: style.itemURL))
                    }
                    .tag(style.itemURL)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct DetailView: View {
    @EnvironmentObject private var model: StudioModel
    @State private var color = Color(nsColor: .systemBlue)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let url = model.selectedURL, let style = model.style {
                itemHeader(url: url)

                Form {
                    Section("Color") {
                        HStack {
                            ColorPicker("Folder Color", selection: $color, supportsOpacity: false)
                                .onChange(of: color) { _, newValue in
                                    model.applyColor(NSColor(newValue))
                                }

                            Button(role: .destructive) {
                                model.restoreOriginal()
                            } label: {
                                Label("Restore Original", systemImage: "arrow.counterclockwise")
                            }
                        }
                    }

                    Section("Image") {
                        HStack {
                            Button {
                                model.choosePhoto()
                            } label: {
                                Label("Add Photo", systemImage: "photo")
                            }

                            Text("Use a picture as this item's icon.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Current Style") {
                        LabeledContent("Treatment", value: style.treatment.displayName)
                        LabeledContent("Name", value: url.lastPathComponent)
                        LabeledContent("Location", value: url.deletingLastPathComponent().path)
                    }
                }
                .formStyle(.grouped)
                .onAppear {
                    color = Color(nsColor: style.color.nsColor)
                }
            } else {
                ContentUnavailableView(
                    "Choose an item",
                    systemImage: "folder",
                    description: Text("Select a Finder item to customize its icon.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if let error = model.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding([.horizontal, .bottom])
            }
        }
    }

    private func itemHeader(url: URL) -> some View {
        HStack(spacing: 16) {
            Image(nsImage: model.icon(for: url))
                .resizable()
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(url.lastPathComponent)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text(url.path)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(24)
        .background(.bar)
    }
}
