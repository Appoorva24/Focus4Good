import SwiftUI
import PencilKit

/// A SwiftUI wrapper around PKCanvasView for freeform drawing.
struct BraindumpCanvasView: UIViewRepresentable {

    @Binding var canvasData: Data
    @Binding var hasDrawing: Bool
    @Binding var isActive: Bool
    @Binding var clearTrigger: UUID
    @Binding var undoTrigger: UUID

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false

        // Show the system tool picker
        let toolPicker = PKToolPicker()
        context.coordinator.toolPicker = toolPicker
        context.coordinator.lastClearTrigger = clearTrigger
        context.coordinator.lastUndoTrigger = undoTrigger

        if isActive {
            toolPicker.setVisible(true, forFirstResponder: canvas)
            toolPicker.addObserver(canvas)
            canvas.becomeFirstResponder()
        }

        // Restore any previously saved drawing
        if !canvasData.isEmpty {
            do {
                let drawing = try PKDrawing(data: canvasData)
                canvas.drawing = drawing
            } catch {
                print("BraindumpCanvasView: failed to load drawing — \(error)")
            }
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        guard let toolPicker = context.coordinator.toolPicker else { return }

        // Handle clear trigger
        if context.coordinator.lastClearTrigger != clearTrigger {
            context.coordinator.lastClearTrigger = clearTrigger
            context.coordinator.isClearingCanvas = true
            uiView.drawing = PKDrawing()
            context.coordinator.isClearingCanvas = false
        }
        
        // Handle undo trigger
        if context.coordinator.lastUndoTrigger != undoTrigger {
            context.coordinator.lastUndoTrigger = undoTrigger
            uiView.undoManager?.undo()
        }

        if isActive {
            toolPicker.setVisible(true, forFirstResponder: uiView)
            toolPicker.addObserver(uiView)
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
            toolPicker.setVisible(false, forFirstResponder: uiView)
            toolPicker.removeObserver(uiView)
        }
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        coordinator.toolPicker?.setVisible(false, forFirstResponder: uiView)
        coordinator.toolPicker?.removeObserver(uiView)
        coordinator.toolPicker = nil
        uiView.resignFirstResponder()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasData: $canvasData, hasDrawing: $hasDrawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var canvasData: Binding<Data>
        var hasDrawing: Binding<Bool>
        var toolPicker: PKToolPicker?
        var lastClearTrigger: UUID = UUID()
        var lastUndoTrigger: UUID = UUID()
        var isClearingCanvas = false

        init(canvasData: Binding<Data>, hasDrawing: Binding<Bool>) {
            self.canvasData = canvasData
            self.hasDrawing = hasDrawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isClearingCanvas else { return }
            let drawing = canvasView.drawing
            canvasData.wrappedValue = drawing.dataRepresentation()
            hasDrawing.wrappedValue = !drawing.strokes.isEmpty
        }
    }
}
