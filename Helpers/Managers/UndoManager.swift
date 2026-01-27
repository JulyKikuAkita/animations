//
//  UndoManager.swift
//  animation
//
//  Created on 1/26/26.

import SwiftUI

struct UndoStateDemoView: View {
    @State private var showDetailView: Bool = false
    var body: some View {
        NavigationStack {
            Button("Detail View") {
                showDetailView.toggle()
            }
            .navigationTitle("@UndoState")
        }
        .sheet(isPresented: $showDetailView) {
            DetailSettingView()
        }
    }
}

/// Note: navigation stack does not release the objects when the associated view is removed (deinit) esp below
///  .navigationDestination(isPresented)
///  NavigationLink(label, view)
struct DetailSettingView: View {
    @UndoState private var sliderValue: CGFloat = 0
    @UndoState private var isMuted: Bool = false
    var body: some View {
        List {
            Section("Volume") {
                Slider(value: $sliderValue, in: 0 ... 100) { status in
                    if status {
                        /// Registering undo before value change
                        _sliderValue.registerUndo()
                    }
                }
                Toggle("Mute Audio", isOn: _isMuted.undoBinding)
                Button("Set 80% Volume") {
                    _sliderValue.registerUndo()
                    sliderValue = 80
                }
            }

            Section("Undo/Redo") {
                Button("Undo") {
                    _sliderValue.undo()
                }
                Button("Redo") {
                    _sliderValue.redo()
                }
            }
        }
    }
}

@Observable
class UndoObject<Value: Equatable> {
    var value: Value
    var storedUndoManager: UndoManager?
    init(value: Value) {
        self.value = value
    }

    deinit {
        /// reset shared state when view is closed
        storedUndoManager?.removeAllActions(withTarget: self)
        print("Object deinit")
    }

    func registerUndo(_ manager: UndoManager?) {
        storedUndoManager = manager
        guard let manager else { return }
        let oldValue = value
        manager.registerUndo(withTarget: self) { target in
            target.registerUndo(manager)
            target.value = oldValue
        }
    }
}

extension UndoObject: @unchecked Sendable {}

@MainActor
@propertyWrapper
struct UndoState<Value: Equatable>: DynamicProperty {
    @State private var undoObject: UndoObject<Value>
    @Environment(\.undoManager) private var undoManager

    var wrappedValue: Value {
        get { undoObject.value }
        nonmutating set { undoObject.value = newValue }
    }

    /// For binding ($propertyName) usage
    var projectedValue: Binding<Value> {
        .init {
            undoObject.value
        } set: { newValue in
            undoObject.value = newValue
        }
    }

    /// Auto registering undo/redo binding value (_propertyName.undoBinding)
    var undoBinding: Binding<Value> {
        .init {
            undoObject.value
        } set: { newValue in
            undoObject.registerUndo(undoManager)
            undoObject.value = newValue
        }
    }

    init(wrappedValue: Value) {
        _undoObject = .init(wrappedValue: .init(value: wrappedValue))
    }

    func registerUndo() {
        undoObject.registerUndo(undoManager)
    }

    func undo() {
        undoManager?.undo()
    }

    func redo() {
        undoManager?.redo()
    }
}
