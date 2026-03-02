import SwiftUI

struct CategoryDetailView: View {
    var category: Category
    var viewModel: ExpenseViewModel

    // Параметры, приходящие из StatsView
    var initialPeriod: StatsView.TimePeriod
    var initialStartDate: Date
    var initialEndDate: Date
    
    // Локальное состояние
    @State private var selectedPeriod: StatsView.TimePeriod
    @State private var startDate: Date
    @State private var endDate: Date
    
    init(
        category: Category,
        viewModel: ExpenseViewModel,
        initialPeriod: StatsView.TimePeriod,
        initialStartDate: Date,
        initialEndDate: Date
    ) {
        self.category = category
        self.viewModel = viewModel
        self.initialPeriod = initialPeriod
        self.initialStartDate = initialStartDate
        self.initialEndDate = initialEndDate
        
        _selectedPeriod = State(initialValue: initialPeriod)
        _startDate = State(initialValue: initialStartDate)
        _endDate = State(initialValue: initialEndDate)
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
                        Text("На этой неделе").tag(StatsView.TimePeriod.thisWeek)
                        Text("В этом месяце").tag(StatsView.TimePeriod.thisMonth)
                        Text("В этом году").tag(StatsView.TimePeriod.thisYear)
                        Text("Пользовательский").tag(StatsView.TimePeriod.custom)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if selectedPeriod == .custom {
                        HStack(spacing: 24) {
                            VStack {
                                Text("От")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "ru_RU"))
                            }

                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 1, height: 32)

                            VStack {
                                Text("До")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "ru_RU"))
                            }
                        }
                        .frame(maxWidth: .infinity)
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
            let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: start, to: Date())
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: Date())
            let start = calendar.date(from: components) ?? Date()
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: start, to: Date())
        case .thisYear:
            var components = calendar.dateComponents([.year], from: Date())
            components.month = 1
            components.day = 1
            let start = calendar.date(from: components) ?? Date()
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: start, to: Date())
        case .custom:
            return viewModel.getExpensesForCategoryInPeriod(category: category, from: startDate, to: endDate)
        }
    }
}
