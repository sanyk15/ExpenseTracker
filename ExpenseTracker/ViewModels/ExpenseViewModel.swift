import Foundation
import Observation
import UIKit

@Observable
class ExpenseViewModel {
    // MARK: - Properties
    var expenses: [Expense] = []
    var categories: [Category] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Init
    init() {
        loadCategories()
        loadExpenses()
    }
    
    // MARK: - Categories Management
    func loadCategories() {
        // Сначала пытаемся загрузить из UserDefaults
        if let saved = UserDefaults.standard.data(forKey: "categories"),
           let decoded = try? JSONDecoder().decode([Category].self, from: saved) {
            self.categories = decoded
        } else {
            // Если первый запуск, используем дефолтные
            self.categories = defaultCategories
            saveCategories()
        }
    }
    
    func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "categories")
        }
    }
    
    func addCategory(_ category: Category) {
        categories.append(category)
        saveCategories()
    }
    
    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        // Удали также траты в этой категории
        expenses.removeAll { $0.category.id == category.id }
        saveCategories()
        saveExpenses()
    }
    
    // MARK: - Expenses Management
    func loadExpenses() {
        if let saved = UserDefaults.standard.data(forKey: "expenses"),
           let decoded = try? JSONDecoder().decode([Expense].self, from: saved) {
            self.expenses = decoded
        }
    }
    
    func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: "expenses")
        }
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        expenses.sort { $0.date > $1.date }
        saveExpenses()
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }
    
    func editExpense(_ expense: Expense, newExpense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = newExpense
            saveExpenses()
        }
    }
    
    // MARK: - Statistics
    func getExpensesForDate(_ date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    func getExpensesForMonth(_ date: Date) -> [Expense] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return expenses.filter { expense in
            let expenseComponents = calendar.dateComponents([.year, .month], from: expense.date)
            return expenseComponents.year == components.year &&
            expenseComponents.month == components.month
        }
    }
    
    func getExpensesForPeriod(from startDate: Date, to endDate: Date) -> [Expense] {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    func getCategoryStatistics(for expenses: [Expense]) -> [CategoryStatistics] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category.id })
        let total = expenses.reduce(0) { $0 + $1.amount }
        
        return grouped.compactMap { categoryId, categoryExpenses in
            guard let category = self.categories.first(where: { $0.id == categoryId }) else {
                return nil
            }
            
            let categoryTotal = categoryExpenses.reduce(0) { $0 + $1.amount }
            let percentage = total > 0 ? (categoryTotal / total) * 100 : 0
            
            return CategoryStatistics(
                category: category,
                total: categoryTotal,
                percentage: percentage
            )
        }.sorted { $0.total > $1.total }
    }
    
    func getMonthlyStatistics(for expenses: [Expense]) -> [MonthlyStatistics] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { expense -> Date in
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            return calendar.date(from: components) ?? Date()
        }
        
        return grouped.map { date, monthExpenses in
            let total = monthExpenses.reduce(0) { $0 + $1.amount }
            return MonthlyStatistics(month: date, total: total)
        }.sorted { $0.month < $1.month }
    }
    
    func getTotalForPeriod(_ expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func compareWithPreviousPeriod(current: [Expense], previous: [Expense]) -> (current: Double, previous: Double, percentChange: Double) {
        let currentTotal = getTotalForPeriod(current)
        let previousTotal = getTotalForPeriod(previous)
        let change = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal) * 100 : 0
        
        return (currentTotal, previousTotal, change)
    }
    
    // MARK: - Helpers
    func copyExpensesToClipboard(_ expenses: [Expense]) {
        var text = "Расходы за день:\n\n"
        for expense in expenses {
            text += "\(expense.category.icon) \(expense.category.name): \(expense.formattedAmount)"
            if let note = expense.note, !note.isEmpty {
                text += " (\(note))"
            }
            text += "\n"
        }
        text += "\nИтого: \(String(format: "%.2f ₽", getTotalForPeriod(expenses)))"
        
        UIPasteboard.general.string = text
    }
    
    // MARK: - Export & Import Data
    func exportDataToJSON() -> Data? {
        let data = [
            "categories": categories,
            "expenses": expenses
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            return jsonData
        } catch {
            errorMessage = "Ошибка при экспорте: \(error.localizedDescription)"
            return nil
        }
    }
}
