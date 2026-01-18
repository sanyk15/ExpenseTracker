import SwiftUI

struct CategoryEditView: View {
    var viewModel: ExpenseViewModel
    var category: Category
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var color: String = ""
    
    var body: some View {
        Form {
            Section("Название") {
                TextField("Название категории", text: $name)
            }
            
            Section("Эмодзи") {
                TextField("Выбери эмодзи", text: $icon)
            }
            
            Section("Цвет (hex)") {
                TextField("Цвет", text: $color)
            }
            
            Section {
                Button("Сохранить") {
                    save()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(name.isEmpty || icon.isEmpty)
            }
        }
        .navigationTitle("Редактировать категорию")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = category.name
            icon = category.icon
            color = category.color
        }
    }
    
    private func save() {
        let updatedCategory = Category(
            id: category.id,
            name: name,
            color: color,
            icon: icon
        )
        viewModel.editCategory(category, newCategory: updatedCategory)
        dismiss()
    }
}
