import SwiftUI
import PencilKit

struct BraindumpHomeView: View {

    @Environment(CalmCentreStore.self) private var store

    private var entries: [BrainDumpEntry] {
        store.recentBrainDumpEntries
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }

            NavigationLink {
                BraindumpWriteView()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("Braindump")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("No Dumps Yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Tap + to write or draw your first braindump.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.appGradient.ignoresSafeArea())
    }

    // MARK: - Entries List

    private var entriesList: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink {
                    BraindumpDetailView(entry: entry)
                } label: {
                    entryRow(entry)
                }
            }
            .onDelete(perform: deleteEntry)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.appGradient.ignoresSafeArea())
    }

    private func entryRow(_ entry: BrainDumpEntry) -> some View {
        HStack(spacing: 14) {
            // Thumbnail
            if let data = entry.drawingData, !data.isEmpty,
               let drawing = try? PKDrawing(data: data) {
                let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                // Title (user-given name) or fallback
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                } else if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                } else {
                    Text("Drawing")
                        .font(.body)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 8) {
                    Text(entry.createdAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.drawingData != nil && !entry.content.isEmpty {
                        Label("Drawing", systemImage: "hand.draw")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

        }
        .padding(.vertical, 4)
    }

    private func deleteEntry(at offsets: IndexSet) {
        for entry in offsets.map({ entries[$0] }) {
            store.deleteBrainDumpEntry(entry)
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpHomeView()
            .environment(CalmCentreStore.shared)
    }
}
