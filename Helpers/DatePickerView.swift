//
//  DatePickerView.swift
//  animation
// Note: 
// conflicting with other uiview layout constraint

import SwiftUI

struct DatePickerTextFieldView: View {
    /// View properties
    @State private var date: Date = .now
    var body: some View {
        NavigationStack {
            DateTimePicker(date: $date) { date in
                return date.formatted()
            }
            .navigationTitle("Date Picker Textfield")
        }
    }
}

struct DateTimePicker: View {
    /// Config
    var components: DatePickerComponents = [.date, .hourAndMinute]
    @Binding var date: Date
    var formattedString: (Date) -> String
    
    /// View properties
    @State private var viewID: String = UUID().uuidString
    @FocusState private var isActive
    var body: some View {
        TextField(viewID, text: .constant(formattedString(date)))
            .focused($isActive)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isActive = false
                    }
                    .tint(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .overlay {
                AddInputViewToTextField(id: viewID) {
                    // Swift UI date picker
                    DatePicker("", selection: $date, displayedComponents: components)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                }
                .onTapGesture {
                    isActive = true
                }
            }
    }
        
}

fileprivate struct AddInputViewToTextField<Content: View>: UIViewRepresentable {
    var id: String
    @ViewBuilder var content: Content
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let window = view.window,
               let textField = window.allSubViews(type: UITextField.self).first(where: { $0.placeholder == id }) {
                textField.tintColor = .clear // don't show textfield cursor
                
                /// Converting SwiftUI view to UiKit View
                let hostView = UIHostingController(rootView: content).view!
                hostView.backgroundColor = .clear
                hostView.frame.size = hostView.intrinsicContentSize
                
                /// Adding as input view
                textField.inputView = hostView
                textField.reloadInputViews()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

fileprivate extension UIView {
    func allSubViews<T: UIView>(type: T.Type) -> [T] {
        var resultViews = subviews.compactMap({ $0 as? T })
        
        for view in resultViews {
            resultViews.append(contentsOf: view.allSubViews(type: type))
        }
        
        return resultViews
    }
}

#Preview {
    DatePickerTextFieldView()
}
