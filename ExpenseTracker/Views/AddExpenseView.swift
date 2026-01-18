import SwiftUI

struct AddExpenseView: View {
    var viewModel: ExpenseViewModel
    @Binding var isPresented: Bool
    
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate = Date()
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Сумма") {
                    HStack {
                        TextField("Сумма", text: $amount)
                            .keyboardType(.decimalPad)
                        Text("₽")
                    }
                }
                
                Section("Категория") {
                    if let selected = selectedCategory {
                        HStack {
                            Text(selected.icon)
                                .font(.title2)
                            Text(selected.name)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = nil
                        }
                    } else {
                        Text("Нажми чтобы выбрать категорию")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if selectedCategory == nil {
                    Section("Доступные категории") {
                        ForEach(viewModel.categories) { category in
                            HStack {
                                Text(category.icon)
                                    .font(.title2)
                                Text(category.name)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                Section("Дата") {
                    DatePicker(
                        "Дата",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                }
                
                Section("Примечание (опционально)") {
                    TextField("Добавь описание", text: $note)
                }
            }
            .navigationTitle("Добавить расход")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        saveExpense()
                    }
                    .disabled(amount.isEmpty || selectedCategory == nil)
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountDouble = Double(amount),
              let category = selectedCategory else { return }
        
        let expense = Expense(
            amount: amountDouble,
            category: category,
            date: selectedDate,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.addExpense(expense)
        isPresented = false
    }
}
