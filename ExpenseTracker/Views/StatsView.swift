import SwiftUI

struct StatsView: View {
    var viewModel: ExpenseViewModel
    @State private var selectedTab = StatsTab.expenses
    @State private var selectedPeriod = TimePeriod.thisMonth
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate = Date()
    
    enum StatsTab {
        case expenses
        case balance
    }
    
    enum TimePeriod {
        case thisWeek
        case thisMonth
        case thisYear
        case custom
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Period picker
                Picker("Период", selection: $selectedPeriod) {
                    Text("Неделя").tag(TimePeriod.thisWeek)
                    Text("Месяц").tag(TimePeriod.thisMonth)
                    Text("Год").tag(TimePeriod.thisYear)
                    Text("Свой период").tag(TimePeriod.custom)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedPeriod == .custom {
                    HStack {
                        DatePicker("От", selection: $startDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                        DatePicker("До", selection: $endDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                    }
                    .padding()
                }
                
                // Tabs
                Picker("", selection: $selectedTab) {
                    Text("Расходы").tag(StatsTab.expenses)
                    Text("Доходы").tag(StatsTab.balance)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    if selectedTab == .expenses {
                        ExpensesStatsContent(viewModel: viewModel, period: selectedPeriod, startDate: startDate, endDate: endDate)
                    } else {
                        BalanceStatsContent(viewModel: viewModel, period: selectedPeriod, startDate: startDate, endDate: endDate)
                    }
                }
            }
            .navigationTitle("Статистика")
            .preferredColorScheme(.light)
        }
    }
}

// MARK: - Expenses Stats Content
struct ExpensesStatsContent: View {
    var viewModel: ExpenseViewModel
    var period: StatsView.TimePeriod
    var startDate: Date
    var endDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            let expenses = expensesForPeriod
            let totalExpense = viewModel.getTotalForPeriod(expenses)
            
            // Total card
            HStack {
                VStack(alignment: .leading) {
                    Text("Всего расходов")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f ₽", totalExpense))
                        .font(.title2)
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            // Category breakdown
            if !expenses.isEmpty {
                Text("По категориям")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                let grouped = Dictionary(grouping: expenses, by: { $0.category.id })
                let sortedCategories = grouped.sorted {
                    let total1 = viewModel.getTotalForPeriod($0.value)
                    let total2 = viewModel.getTotalForPeriod($1.value)
                    return total1 > total2
                }
                
                ForEach(sortedCategories, id: \.key) { _, categoryExpenses in
                    if let category = categoryExpenses.first?.category {
                        let categoryTotal = viewModel.getTotalForPeriod(categoryExpenses)
                        let percentage = (categoryTotal / totalExpense) * 100
                        
                        NavigationLink(destination: CategoryDetailView(category: category, expenses: categoryExpenses, viewModel: viewModel)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(category.icon)
                                            .font(.title3)
                                        Text(category.name)
                                            .font(.body)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.gray.opacity(0.2))
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.red.opacity(0.7))
                                                .frame(width: geometry.size.width * CGFloat(percentage / 100))
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.2f ₽", categoryTotal))
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    Text(String(format: "%.1f%%", percentage))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    var expensesForPeriod: [Expense] {
        let calendar = Calendar.current
        switch period {
        case .thisWeek:
            let start = calendar.date(byAdding: .day, value: -7, to: Date())!
            return viewModel.getExpensesForPeriod(from: start, to: Date())
        case .thisMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: Date())!
            return viewModel.getExpensesForPeriod(from: start, to: Date())
        case .thisYear:
            let start = calendar.date(byAdding: .year, value: -1, to: Date())!
            return viewModel.getExpensesForPeriod(from: start, to: Date())
        case .custom:
            return viewModel.getExpensesForPeriod(from: startDate, to: endDate)
        }
    }
}

// MARK: - Balance Stats Content (Доходы)
struct BalanceStatsContent: View {
    var viewModel: ExpenseViewModel
    var period: StatsView.TimePeriod
    var startDate: Date
    var endDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            let incomes = incomesForPeriod
            let totalIncome = viewModel.getTotalIncomeForPeriod(incomes)
            
            // Total income card
            HStack {
                VStack(alignment: .leading) {
                    Text("Всего доходов")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f ₽", totalIncome))
                        .font(.title2)
                        .foregroundColor(.green)
                }
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            // Incomes by source
            if !incomes.isEmpty {
                Text("Источники доходов")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 12) {
                        let grouped = Dictionary(grouping: incomes, by: { $0.note ?? "Без категории" })
                        let sortedSources = grouped.sorted {
                            let total1 = $0.value.reduce(0) { $0 + $1.amount }
                            let total2 = $1.value.reduce(0) { $0 + $1.amount }
                            return total1 > total2
                        }
                        
                        ForEach(sortedSources, id: \.key) { source, sourceIncomes in
                            IncomeSourceView(
                                source: source,
                                sourceIncomes: sourceIncomes,
                                totalIncome: totalIncome
                            )
                        }
                    }
                }
            }
        }
    }
    
    var incomesForPeriod: [Income] {
        let calendar = Calendar.current
        switch period {
        case .thisWeek:
            let start = calendar.date(byAdding: .day, value: -7, to: Date())!
            return viewModel.getIncomesForPeriod(from: start, to: Date())
        case .thisMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: Date())!
            return viewModel.getIncomesForPeriod(from: start, to: Date())
        case .thisYear:
            let start = calendar.date(byAdding: .year, value: -1, to: Date())!
            return viewModel.getIncomesForPeriod(from: start, to: Date())
        case .custom:
            return viewModel.getIncomesForPeriod(from: startDate, to: endDate)
        }
    }
}

// MARK: - Incomes List View
struct IncomesListView: View {
    let incomes: [Income]
    let totalIncome: Double
    
    var body: some View {
        let grouped = Dictionary(grouping: incomes, by: { $0.note ?? "Без категории" })
        let sortedSources = grouped.sorted {
            let total1 = $0.value.reduce(0) { $0 + $1.amount }
            let total2 = $1.value.reduce(0) { $0 + $1.amount }
            return total1 > total2
        }
        
        VStack(spacing: 12) {  // ← Убрал "return"
            ForEach(sortedSources, id: \.key) { source, sourceIncomes in
                IncomeSourceView(
                    source: source,
                    sourceIncomes: sourceIncomes,
                    totalIncome: totalIncome
                )
            }
        }
    }
}

// MARK: - Income Source View
struct IncomeSourceView: View {
    let source: String
    let sourceIncomes: [Income]
    let totalIncome: Double
    
    var body: some View {
        let sourceTotal = sourceIncomes.reduce(0) { $0 + $1.amount }
        let percentage = (sourceTotal / totalIncome) * 100
        let sortedIncomes = sourceIncomes.sorted { $0.date > $1.date }
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(source)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.7))
                                .frame(width: geometry.size.width * CGFloat(percentage / 100))
                        }
                    }
                    .frame(height: 8)
                }
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.2f ₽", sourceTotal))
                        .font(.body)
                        .fontWeight(.semibold)
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Список доходов
            VStack(spacing: 8) {
                ForEach(sortedIncomes, id: \.id) { income in
                    IncomeItemRow(income: income)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Income Item Row
struct IncomeItemRow: View {
    let income: Income
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        return dateFormatter.string(from: income.date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(income.note ?? "Доход")
                    .font(.body)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(String(format: "%.2f ₽", income.amount))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}


// MARK: - Bar Chart Component
struct BarChart: View {
    let data: [(String, Double)]
    let color: Color
    
    var maxValue: Double {
        data.map { $0.1 }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(data.indices, id: \.self) { index in
                            let month = data[index].0
                            let value = data[index].1
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color.opacity(0.7))
                                    .frame(width: 30, height: CGFloat(value / maxValue) * 150)
                                
                                Text(month)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            .id(index)
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    scrollProxy.scrollTo(data.count - 1, anchor: .trailing)
                }
            }
            
            HStack {
                Text("Макс: \(String(format: "%.0f ₽", maxValue))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
