import SwiftUI

struct StatsView: View {
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
                    let categoryStats = viewModel.getCategoryStatistics(for: expenses)
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
                    
                    // Category breakdown with bars
                    if !categoryStats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("По категориям")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(categoryStats, id: \.category.id) { stat in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(stat.category.icon)
                                            .font(.title3)
                                        Text(stat.category.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(String(format: "%.2f ₽", stat.total))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    // Bar with percentage
                                    GeometryReader { geometry in
                                        HStack(spacing: 0) {
                                            // Bar
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.6))
                                                .frame(width: geometry.size.width * (stat.percentage / 100))
                                            
                                            Spacer()
                                        }
                                        .frame(height: 24)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                        
                                        // Percentage text in the middle
                                        HStack {
                                            Spacer()
                                            Text(String(format: "%.1f%%", stat.percentage))
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black)
                                            Spacer()
                                        }
                                        .frame(height: 24)
                                    }
                                    .frame(height: 24)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Monthly comparison
                    let monthlyStats = viewModel.getMonthlyStatistics(for: expenses)
                    if !monthlyStats.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Расходы по месяцам")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .center, spacing: 8) {
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(monthlyStats, id: \.month) { stat in
                                        VStack(spacing: 4) {
                                            let maxValue = monthlyStats.map { $0.total }.max() ?? 1
                                            let height = CGFloat(stat.total / maxValue * 120)
                                            
                                            // Amount text above bar
                                            Text(String(format: "%.0f ₽", stat.total))
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .frame(height: 16)
                                            
                                            // Bar
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.blue.opacity(0.6))
                                                .frame(height: height)
                                            
                                            // Month label
                                            Text(dateFormatter(stat.month))
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(height: 180)
                            }
                            .padding()
                        }
                    }
                }
                .navigationTitle("Статистика")
            }
        }
    }
    
    private func expensesForPeriod() -> [Expense] {
        let calendar = Calendar.current
        
        switch selectedPeriod {
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
    
    private func dateFormatter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}
