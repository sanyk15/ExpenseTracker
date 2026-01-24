import SwiftUI

struct AddIncomeView: View {
    var viewModel: ExpenseViewModel
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    
    @State private var amount: String = ""
    @State private var note: String = ""
    
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
                
                Section("Дата") {
                    DatePicker("Дата", selection: $selectedDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                }
                
                Section("Комментарий") {
                    TextField("Откуда доход? (опционально)", text: $note)
                }
            }
            .navigationTitle("Новый доход")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        addIncome()
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
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
