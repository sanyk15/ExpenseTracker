import SwiftUI

struct StatsView: View {
    var viewModel: ExpenseViewModel
    @State private var selectedTab: StatsTab = .expenses
    @State private var selectedPeriod: TimePeriod = .thisMonth
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
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                        DatePicker("До", selection: $endDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                    }
                    .padding()
                }
                
                // Tabs
                Picker("Вид", selection: $selectedTab) {
                    Text("Расходы").tag(StatsTab.expenses)
                    Text("Баланс").tag(StatsTab.balance)
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
            let expenses = expensesForPeriod()
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
                ForEach(grouped.sorted(by: { $0.value.reduce(0) { $0 + $1.amount } > $1.value.reduce(0) { $0 + $1.amount } }), id: \.key) { _, categoryExpenses in
                    if let category = categoryExpenses.first?.category {
                        let categoryTotal = viewModel.getTotalForPeriod(categoryExpenses)
                        let percentage = (categoryTotal / totalExpense) * 100
                        
                        NavigationLink(destination: CategoryDetailView(category: category, expenses: categoryExpenses.sorted(by: { $0.date > $1.date }), viewModel: viewModel)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(category.icon)
                                            .font(.title3)
                                        Text(category.name)
                                            .font(.body)
                                    }
                                    
                                    // Progress bar
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
    
    private func expensesForPeriod() -> [Expense] {
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

// MARK: - Balance Stats Content
struct BalanceStatsContent: View {
    var viewModel: ExpenseViewModel
    var period: StatsView.TimePeriod
    var startDate: Date
    var endDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            let incomes = incomesForPeriod()
            let expenses = expensesForPeriod()
            let totalIncome = viewModel.getTotalIncomeForPeriod(incomes)
            let totalExpense = viewModel.getTotalForPeriod(expenses)
            let balance = totalIncome - totalExpense
            
            // Summary cards
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Доходы")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f ₽", totalIncome))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Расходы")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f ₽", totalExpense))
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Баланс")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f ₽", balance))
                            .font(.headline)
                            .foregroundColor(balance >= 0 ? .green : .red)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
            
            // Pie chart
            if totalIncome > 0 && totalExpense > 0 {
                Text("Соотношение доходов и расходов")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                VStack(spacing: 20) {
                    PieChartView(
                        incomeAmount: totalIncome,
                        expenseAmount: totalExpense
                    )
                    .frame(height: 250)
                    
                    HStack(spacing: 20) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Доходы")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(String(format: "%.1f%%", (totalIncome / (totalIncome + totalExpense)) * 100))
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Расходы")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(String(format: "%.1f%%", (totalExpense / (totalIncome + totalExpense)) * 100))
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    private func incomesForPeriod() -> [Income] {
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
    
    private func expensesForPeriod() -> [Expense] {
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

// MARK: - Pie Chart Component
struct PieChartView: View {
    var incomeAmount: Double
    var expenseAmount: Double
    
    var body: some View {
        Canvas { context, size in
            let total = incomeAmount + expenseAmount
            let incomePercentage = incomeAmount / total
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let radius: CGFloat = 80
            
            // Green slice (income)
            var path = Path()
            path.move(to: CGPoint(x: centerX, y: centerY))
            path.addArc(
                center: CGPoint(x: centerX, y: centerY),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(incomePercentage * 360),
                clockwise: false
            )
            path.closeSubpath()
            context.fill(path, with: .color(.green))
            
            // Red slice (expense)
            path = Path()
            path.move(to: CGPoint(x: centerX, y: centerY))
            path.addArc(
                center: CGPoint(x: centerX, y: centerY),
                radius: radius,
                startAngle: .degrees(incomePercentage * 360),
                endAngle: .degrees(360),
                clockwise: false
            )
            path.closeSubpath()
            context.fill(path, with: .color(.red))
            
            // Center circle (for donut effect)
            var circlePath = Path()
            circlePath.addEllipse(in: CGRect(x: centerX - 40, y: centerY - 40, width: 80, height: 80))
            context.fill(circlePath, with: .color(.white))
        }
    }
}
