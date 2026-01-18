import SwiftUI

struct AddIncomeView: View {
    var viewModel: ExpenseViewModel
    @Binding var isPresented: Bool
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
                TextField("Откуда доход? (опционально)", text: $note)
            }
            
            Section {
                Button("Добавить доход") {
                    addIncome()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(amount.isEmpty)
            }
        }
        .navigationTitle("Новый доход")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addIncome() {
        guard let amountDouble = Double(amount) else { return }
        
        let income = Income(
            amount: amountDouble,
            date: selectedDate,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.addIncome(income)
        isPresented = false
    }
}
