import SwiftUI

struct EditIncomeView: View {
    var viewModel: ExpenseViewModel
    var income: Income
    @Environment(\.dismiss) var dismiss
    
    @State private var amount: String = ""
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
            
            Section("Дата") {
                DatePicker("Дата", selection: $selectedDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "ru_RU"))
            }
            
            Section("Комментарий") {
                TextField("Откуда доход?", text: $note)
            }
            
            Section {
                Button("Сохранить") {
                    save()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(amount.isEmpty)
            }
        }
        .navigationTitle("Редактировать доход")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            amount = String(format: "%.2f", income.amount)
            selectedDate = income.date
            note = income.note ?? ""
        }
    }
    
    private func save() {
        guard let amountDouble = Double(amount) else { return }
        
        let newIncome = Income(
            id: income.id,
            amount: amountDouble,
            date: selectedDate,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.editIncome(income, newIncome: newIncome)
        dismiss()
    }
}
