import SwiftUI
import VisionKit

// MARK: - Scan Notes View
/// Uses Apple VisionKit's DataScannerViewController (Live Text Camera) or
/// VNDocumentCameraViewController to scan handwritten notes and extract text.
/// Extracted text is parsed into individual tasks for user review.

struct ScanNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDocumentScanner = false
    @State private var recognizedText: String = ""
    @State private var parsedTasks: [ScannedTask] = []
    @State private var showReview = false
    @State private var scanError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentLight)
                        .frame(width: 120, height: 120)
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 52))
                        .foregroundStyle(AppTheme.orange)
                }

                VStack(spacing: 10) {
                    Text("Scan Handwritten Notes")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Point your camera at your handwritten task list.\nWe'll recognize the text and create tasks for you.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 24)

                Spacer()

                if let error = scanError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                // Scan Button
                Button {
                    showDocumentScanner = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        Text("Open Camera Scanner")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [AppTheme.orange, Color(hex: "F4845F")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                    .shadow(color: AppTheme.orange.opacity(0.3), radius: 10, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .navigationTitle("Scan Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScannerView(recognizedText: $recognizedText) { text in
                    parsedTasks = parseTasksFromText(text)
                    if parsedTasks.isEmpty {
                        scanError = "No tasks could be recognized. Try again with clearer handwriting."
                    } else {
                        showReview = true
                    }
                }
            }
            .navigationDestination(isPresented: $showReview) {
                ScannedTasksReviewView(scannedTasks: $parsedTasks, onDismissAll: {
                    dismiss()
                })
            }
        }
    }

    /// Parse recognized text into individual task items
    /// Each line that has meaningful content becomes a task
    private func parseTasksFromText(_ text: String) -> [ScannedTask] {
        let lines = text.components(separatedBy: .newlines)
        var tasks: [ScannedTask] = []

        for line in lines {
            // Clean up the line
            var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            guard !cleaned.isEmpty else { continue }
            // Skip lines that are too short (noise)
            guard cleaned.count >= 2 else { continue }

            // Remove common list prefixes: bullets, dashes, numbers, etc.
            let prefixPatterns = ["• ", "- ", "– ", "— ", "* ", "> "]
            for prefix in prefixPatterns {
                if cleaned.hasPrefix(prefix) {
                    cleaned = String(cleaned.dropFirst(prefix.count))
                }
            }
            // Remove numbered prefixes like "1. ", "2) ", "1- "
            if let range = cleaned.range(of: #"^\d+[\.\)\-]\s*"#, options: .regularExpression) {
                cleaned = String(cleaned[range.upperBound...])
            }

            // Remove checkbox prefixes like "[ ] ", "[x] "
            if let range = cleaned.range(of: #"^\[.?\]\s*"#, options: .regularExpression) {
                cleaned = String(cleaned[range.upperBound...])
            }

            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty, cleaned.count >= 2 else { continue }

            tasks.append(ScannedTask(title: cleaned))
        }

        return tasks
    }
}

// MARK: - Scanned Task Model

struct ScannedTask: Identifiable {
    let id = UUID()
    var title: String
    var pomodoroSlots: Int = 1  // Default: 1 session (25 min)
    var isSelected: Bool = true  // Whether to include this task
}

// MARK: - Document Scanner (VNDocumentCameraViewController wrapper)

import Vision

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    var onComplete: (String) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                           didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)

            // Process all scanned pages
            Task {
                var allText = ""
                for pageIndex in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: pageIndex)
                    let text = await recognizeText(from: image)
                    allText += text + "\n"
                }
                let finalFormattedText = allText
                await MainActor.run {
                    parent.recognizedText = finalFormattedText
                    parent.onComplete(finalFormattedText)
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                           didFailWithError error: Error) {
            controller.dismiss(animated: true)
            print("❌ Document scan failed: \(error.localizedDescription)")
        }

        /// Use Apple Vision framework to recognize text from scanned image
        private func recognizeText(from image: UIImage) async -> String {
            guard let cgImage = image.cgImage else { return "" }

            return await withCheckedContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: "")
                        return
                    }

                    let recognizedStrings = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }

                    continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ VNRecognizeTextRequest failed: \(error)")
                    continuation.resume(returning: "")
                }
            }
        }
    }
}
