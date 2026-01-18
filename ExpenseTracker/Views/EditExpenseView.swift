import SwiftUI

struct EditExpenseView: View {
    var viewModel: ExpenseViewModel
    var expense: Expense
    @Environment(\.dismiss) var dismiss
    
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate = Date()
    @State private var note: String = ""
    
    var body: some View {
        Form {
            Section("Сумма") {
                HStack {
                    TextField("Сумма", text: $amount)
                        .keyboardType(.decimalPad)
                    Text("₽")
                }
            }
            
            Section("Категория") {
                Picker("Категория", selection: $selectedCategory) {
                    ForEach(viewModel.categories) { category in
                        HStack {
                            Text(category.icon)
                            Text(category.name)
                        }
                        .tag(category as Category?)
                    }
                }
            }
            
            Section("Дата") {
                DatePicker("Дата", selection: $selectedDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "ru_RU"))
            }
            
            Section("Примечание") {
                TextField("Добавь описание", text: $note)
            }
            
            Section {
                Button("Сохранить") {
                    save()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(amount.isEmpty || selectedCategory == nil)
            }
        }
        .navigationTitle("Редактировать расход")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            amount = String(format: "%.2f", expense.amount)
            selectedCategory = expense.category
            selectedDate = expense.date
            note = expense.note ?? ""
        }
    }
    
    private func save() {
        guard let amountDouble = Double(amount),
              let category = selectedCategory else { return }
        
        let newExpense = Expense(
            id: expense.id,
            amount: amountDouble,
            category: category,
            date: selectedDate,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.editExpense(expense, newExpense: newExpense)
        dismiss()
    }
}
