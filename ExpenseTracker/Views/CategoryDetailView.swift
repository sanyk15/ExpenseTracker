import SwiftUI

struct CategoryDetailView: View {
    var category: Category
    var expenses: [Expense]
    var viewModel: ExpenseViewModel
    
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate = Date()
    
    enum TimePeriod {
        case thisWeek
        case thisMonth
        case thisYear
        case custom
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header с категорией
                    VStack(spacing: 8) {
                        Text(category.icon)
                            .font(.system(size: 60))
                        Text(category.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                    
                    // Period picker
                    Picker("Период", selection: $selectedPeriod) {
                        Text("На этой неделе").tag(TimePeriod.thisWeek)
                        Text("В этом месяце").tag(TimePeriod.thisMonth)
                        Text("В этом году").tag(TimePeriod.thisYear)
                        Text("Пользовательский").tag(TimePeriod.custom)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if selectedPeriod == .custom {
                        HStack {
                            DatePicker("От", selection: $startDate, displayedComponents: .date)
                            DatePicker("До", selection: $endDate, displayedComponents: .date)
                        }
                        .padding()
                    }
                    
                    let expenses = expensesForPeriod()
                    let total = viewModel.getTotalForPeriod(expenses)
                    
                    // Total
                    VStack {
                        Text("Всего за период")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f ₽", total))
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Expenses list
                    if !expenses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Траты (\(expenses.count))")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(expenses) { expense in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(expense.formattedDate)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        if let note = expense.note, !note.isEmpty {
                                            Text(note)
                                                .font(.subheadline)
                                        }
                                    }
                                    Spacer()
                                    Text(expense.formattedAmount)
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack {
                            Text("Нет трат в этом периоде")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                        .padding()
                    }
                }
            }
            .navigationTitle("Детали")
        }
    }
    
    private func expensesForPeriod() -> [Expense] {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .thisWeek:
            let start = calendar.date(byAdding: .day, value: -7, to: Date())!
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: start, to: Date())
            
        case .thisMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: Date())!
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: start, to: Date())
            
        case .thisYear:
            let start = calendar.date(byAdding: .year, value: -1, to: Date())!
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: start, to: Date())
            
        case .custom:
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: startDate, to: endDate)
        }
    }
}
