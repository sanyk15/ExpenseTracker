import SwiftUI

struct IncomeView: View {
    var viewModel: ExpenseViewModel
    @State private var showAddIncome = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Дата",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .padding()
                
                let todayIncomes = viewModel.getIncomesForDate(selectedDate)
                
                if todayIncomes.isEmpty {
                    VStack(spacing: 16) {
                        Text("💰")
                            .font(.system(size: 60))
                        Text("Нет доходов")
                            .font(.headline)
                        Text("Добавь свой первый доход")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(todayIncomes) { income in
                            NavigationLink(destination: EditIncomeView(viewModel: viewModel, income: income)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("💵 Доход")
                                            .font(.headline)
                                        if let note = income.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text(income.formattedAmount)
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                                .foregroundColor(.primary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteIncome(income)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                        
                        HStack {
                            Text("Итого:")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f ₽", viewModel.getTotalIncomeForPeriod(todayIncomes)))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Доходы")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                            NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                                Image(systemName: "gearshape.fill")
                            }
                        }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddIncome = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddIncome) {
            NavigationStack {
                AddIncomeView(viewModel: viewModel, isPresented: $showAddIncome, selectedDate: $selectedDate)
            }
        }
    }
}
