import SwiftUI

struct BraindumpEntriesView: View {

    let folder: BrainDumpFolder

    @Environment(CalmCentreStore.self) private var store
    @State private var selectedEntry: BrainDumpEntry?

    private var entries: [BrainDumpEntry] {
        store.brainDumpEntries(in: folder)
    }

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    Button { selectedEntry = entry } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                if let title = entry.title, !title.isEmpty {
                                    Text(title)
                                        .lineLimit(1)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                } else {
                                    Text(entry.content)
                                        .lineLimit(2)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                }

                                Text(entry.createdAt, format: .dateTime.day().month(.wide).year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .tint(.primary)
                }
                .onDelete(perform: deleteEntry)
            } header: {
                if !entries.isEmpty {
                    Text("\(entries.count) \(entries.count == 1 ? "Entry" : "Entries")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    BraindumpEditorView(folder: folder)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.accentColor)
                }
            }

            if !entries.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            entryDetailSheet(entry)
        }
        .overlay {
            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No Entries Yet")
                        .font(.headline)
                    Text("Tap the compose icon to start writing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func entryDetailSheet(_ entry: BrainDumpEntry) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(entry.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Text(entry.content)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(entry.title ?? "Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { selectedEntry = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func deleteEntry(at offsets: IndexSet) {
        for entry in offsets.map({ entries[$0] }) {
            store.deleteBrainDumpEntry(entry)
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpEntriesView(
            folder: BrainDumpFolder(userId: UUID(), name: "Random Thoughts", entryCount: 2)
        )
        .environment(CalmCentreStore.shared)
    }
}
