import SwiftUI
import PencilKit

struct BraindumpWriteView: View {

    enum DumpMode: String, CaseIterable {
        case write = "Write"
        case draw = "Draw"
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(CalmCentreStore.self) private var store
    @FocusState private var isEditorFocused: Bool

    @State private var selectedMode: DumpMode = .write
    @State private var text = ""
    @State private var canvasData = Data()
    @State private var hasDrawing = false
    @State private var showSavedPopup = false
    @State private var showDiscardConfirmation = false
    @State private var showNameAlert = false
    @State private var entryTitle = ""
    @State private var isCanvasActive = false
    @State private var clearTrigger = UUID()
    @State private var undoTrigger = UUID()

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSave: Bool {
        hasText || hasDrawing
    }

    var body: some View {
        ZStack {
            editorContent
            if showSavedPopup { savedOverlay }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showSavedPopup)
        .navigationTitle("Braindump")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .alert("Name your dump", isPresented: $showNameAlert) {
            TextField("", text: $entryTitle)
            Button("Save") { performSave() }
                .tint(.primary)
            Button("Skip", role: .cancel) { showSavedPopup = true }
                .tint(.primary)
        }
        .toolbar(selectedMode == .draw ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.25), value: selectedMode)
        .confirmationDialog(
            "Discard this dump?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                isCanvasActive = false
                dismiss()
            }
            Button("Keep Writing", role: .cancel) {
                if selectedMode == .draw {
                    isCanvasActive = true
                }
            }
        } message: {
            Text("Your thoughts won't be saved. That's okay — the act of writing itself helps clear your mind.")
        }

    }

    // MARK: - Editor

    private var editorContent: some View {
        VStack(spacing: 0) {
            modePicker

            if selectedMode == .write {
                textEditorArea
            } else {
                drawingCanvasArea
            }
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
    }

    private var modePicker: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(DumpMode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode == .write ? "pencil.line" : "hand.draw")
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .onChange(of: selectedMode) { _, newMode in
            if newMode == .write {
                isCanvasActive = false
                isEditorFocused = true
            } else {
                isEditorFocused = false
                isCanvasActive = true
            }
        }
    }

    private var textEditorArea: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isEditorFocused)
                .scrollContentBackground(.hidden)
                .font(.body)
                .padding(16)

            if text.isEmpty {
                Text("Write freely, just get it out of your head…")
                    .font(.body)
                    .foregroundStyle(Color(.placeholderText))
                    .padding(.leading, 21)
                    .padding(.top, 24)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal)
    }

    private var drawingCanvasArea: some View {
        BraindumpCanvasView(canvasData: $canvasData, hasDrawing: $hasDrawing, isActive: $isCanvasActive, clearTrigger: $clearTrigger, undoTrigger: $undoTrigger)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isCanvasActive = false
                if canSave {
                    showDiscardConfirmation = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
        }

        if selectedMode == .draw && hasDrawing {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    undoTrigger = UUID()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button { promptForName() } label: {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.accentColor : Color(.placeholderText))
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Saved Overlay

    private var savedOverlay: some View {
        ZStack {
            AppTheme.appGradient
                .ignoresSafeArea()
                .onTapGesture {
                    showSavedPopup = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.bounce, value: showSavedPopup)

                Text("Mind cleared!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Great job getting those thoughts out.\nYour mind feels lighter already.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 10 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showSavedPopup = false
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Save

    private func promptForName() {
        guard hasText || hasDrawing else { return }
        isEditorFocused = false
        isCanvasActive = false
        entryTitle = ""
        showNameAlert = true
    }

    private func performSave() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = entryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleToSave: String? = trimmedTitle.isEmpty ? nil : trimmedTitle
        let drawingToSave: Data? = hasDrawing ? canvasData : nil

        Task {
            await store.addBrainDumpEntry(
                content: trimmedText,
                drawingData: drawingToSave,
                title: titleToSave,
                userId: UUID(),
                folderId: nil
            )
        }
        showSavedPopup = true
    }
}

#Preview {
    NavigationStack {
        BraindumpWriteView()
            .environment(CalmCentreStore.shared)
    }
}
