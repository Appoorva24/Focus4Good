import SwiftUI
import PencilKit

struct BraindumpDetailView: View {

    let entry: BrainDumpEntry
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date
                    Text(entry.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Drawing
                    if let data = entry.drawingData, !data.isEmpty,
                       let drawing = try? PKDrawing(data: data) {
                        let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemGray6))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    // Text
                    if !entry.content.isEmpty {
                        Text(entry.content)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(AppTheme.appGradient.ignoresSafeArea())
            .navigationTitle(entry.title ?? "Entry")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BraindumpDetailView(
        entry: BrainDumpEntry(
            userId: UUID(),
            content: "I have so many things on my mind right now. Work is stressful and I need to relax.",
            pointsEarned: 10,
            createdAt: Date()
        )
    )
}
