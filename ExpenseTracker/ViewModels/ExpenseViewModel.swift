import Foundation
import Observation
import UIKit

@Observable
class ExpenseViewModel {
    // MARK: - Properties
    var expenses: [Expense] = []
    var categories: [Category] = []
    var incomes: [Income] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Init
    init() {
        loadCategories()
        loadExpenses()
        loadIncomes()
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
    
    // MARK: - Expenses Management (Updated)
    func editExpense(_ expense: Expense, newExpense: Expense) {
        print("🔄 Начинаем редактировать расход")
        print("📌 Старое значение: \(expense.amount)")
        print("📌 Новое значение: \(newExpense.amount)")
        
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = newExpense
            expenses.sort { $0.date > $1.date }
            saveExpenses()
            print("✅ Расход успешно обновлён")
        } else {
            print("❌ Расход не найден!")
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
        let calendar = Calendar.current
        
        let normalizedStart = calendar.startOfDay(for: startDate)
        
        guard let normalizedEnd = calendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: endDate
        ) else {
            return []
        }
        
        return expenses.filter { $0.date >= normalizedStart && $0.date <= normalizedEnd }
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
    
    // MARK: - Helpers (Updated)
    func copyExpensesToClipboard(expenses: [Expense], reportDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let reportDateString = dateFormatter.string(from: reportDate)
        
        var text = "Расходы за \(reportDateString)\n"
        
        for expense in expenses {
            text += "\(expense.category.icon) \(expense.category.name): \(expense.formattedAmount)\n"
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
    
    // MARK: - Category Management (Updated)
    func sortCategories() {
        categories.sort { $0.name < $1.name }
        saveCategories()
    }

    func editCategory(_ category: Category, newCategory: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = newCategory
            // Обнови категорию во всех тратах
            expenses = expenses.map { expense in
                if expense.category.id == category.id {
                    var updatedExpense = expense
                    updatedExpense.category = newCategory
                    return updatedExpense
                }
                return expense
            }
            saveCategories()
            saveExpenses()
        }
    }

    // MARK: - Statistics (New)
    func getExpensesForCategoryInPeriod(category: Category, from startDate: Date, to endDate: Date) -> [Expense] {
        getExpensesForPeriod(from: startDate, to: endDate)
            .filter { $0.category.id == category.id }
    }

    func getCategoryExpensesBreakdown(category: Category) -> [Expense] {
        expenses.filter { $0.category.id == category.id }
            .sorted { $0.date > $1.date }
    }

    // Бесплатный день
    func isFreeDay(_ date: Date) -> Bool {
        getExpensesForDate(date).isEmpty
    }
    
    // MARK: - Income Management
    func loadIncomes() {
        if let saved = UserDefaults.standard.data(forKey: "incomes"),
           let decoded = try? JSONDecoder().decode([Income].self, from: saved) {
            self.incomes = decoded
        }
    }

    func saveIncomes() {
        if let encoded = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(encoded, forKey: "incomes")
        }
    }

    func addIncome(_ income: Income) {
        incomes.append(income)
        incomes.sort { $0.date > $1.date }
        saveIncomes()
    }

    func deleteIncome(_ income: Income) {
        incomes.removeAll { $0.id == income.id }
        saveIncomes()
    }

    func editIncome(_ income: Income, newIncome: Income) {
        if let index = incomes.firstIndex(where: { $0.id == income.id }) {
            incomes[index] = newIncome
            incomes.sort { $0.date > $1.date }
            saveIncomes()
        }
    }

    func getIncomesForDate(_ date: Date) -> [Income] {
        let calendar = Calendar.current
        return incomes.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func getIncomesForMonth(_ date: Date) -> [Income] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return incomes.filter { income in
            let incomeComponents = calendar.dateComponents([.year, .month], from: income.date)
            return incomeComponents.year == components.year &&
                   incomeComponents.month == components.month
        }
    }

    func getIncomesForPeriod(from startDate: Date, to endDate: Date) -> [Income] {
        let calendar = Calendar.current
        
        let normalizedStart = calendar.startOfDay(for: startDate)
        guard let normalizedEnd = calendar.date(
            bySettingHour: 23, minute: 59, second: 59, of: endDate
        ) else {
            return []
        }
        
        return incomes.filter { $0.date >= normalizedStart && $0.date <= normalizedEnd }
    }

    func getTotalIncomeForPeriod(_ incomes: [Income]) -> Double {
        incomes.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Export / Import Data
    func exportData() -> URL? {
        // Конвертируем в простые структуры
        let expensesBackup = expenses.map { expense in
            ExpenseBackup(
                id: expense.id.uuidString,
                amount: expense.amount,
                categoryId: expense.category.id.uuidString,
                date: expense.date,
                note: expense.note
            )
        }
        
        let incomesBackup = incomes.map { income in
            IncomeBackup(
                id: income.id,
                amount: income.amount,
                date: income.date,
                note: income.note
            )
        }
        
        let categoriesBackup = categories.map { category in
            CategoryBackup(
                id: category.id.uuidString,
                name: category.name,
                color: category.color,
                icon: category.icon
            )
        }
        
        let backup = BackupData(
            version: "1.0",
            exportDate: Date(),
            expenses: expensesBackup,
            incomes: incomesBackup,
            categories: categoriesBackup
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let jsonData = try encoder.encode(backup)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "ExpenseTracker_\(dateString).json"
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: tempURL)
            
            return tempURL
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }

    func importData(from url: URL) -> Bool {
        // Явный вывод в консоль через NSLog (работает всегда)
        NSLog("🟢 СТАРТ ИМПОРТА")
        NSLog("📁 URL: \(url.path)")
        
        // Получаем доступ к файлу (важно для iOS)
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // Проверяем существование файла
            guard FileManager.default.fileExists(atPath: url.path) else {
                NSLog("❌ Файл не существует по пути: \(url.path)")
                return false
            }
            
            NSLog("✅ Файл найден")
            
            // Читаем данные
            let jsonData = try Data(contentsOf: url)
            NSLog("✅ Файл прочитан, размер: \(jsonData.count) байт")
            
            // Выводим первые 200 символов JSON
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let preview = String(jsonString.prefix(200))
                NSLog("📄 JSON preview: \(preview)...")
            }
            
            // Декодируем
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let backup = try decoder.decode(BackupData.self, from: jsonData)
            NSLog("✅ JSON декодирован!")
            NSLog("📊 Категорий: \(backup.categories.count)")
            NSLog("📊 Расходов: \(backup.expenses.count)")
            NSLog("📊 Доходов: \(backup.incomes.count)")
            
            // Импорт категорий
            var importedCategories: [Category] = []
            for catBackup in backup.categories {
                guard let id = UUID(uuidString: catBackup.id) else {
                    NSLog("⚠️ Пропуск категории с неверным ID: \(catBackup.id)")
                    continue
                }
                var category = Category(name: catBackup.name, color: catBackup.color, icon: catBackup.icon)
                category.id = id
                importedCategories.append(category)
            }
            self.categories = importedCategories
            saveCategories()
            NSLog("✅ Категории сохранены: \(importedCategories.count)")
            
            // Импорт расходов
            var importedExpenses: [Expense] = []
            for expBackup in backup.expenses {
                guard let id = UUID(uuidString: expBackup.id),
                      let categoryId = UUID(uuidString: expBackup.categoryId),
                      let category = categories.first(where: { $0.id == categoryId }) else {
                    NSLog("⚠️ Пропуск расхода")
                    continue
                }
                
                var expense = Expense(
                    amount: expBackup.amount,
                    category: category,
                    date: expBackup.date,
                    note: expBackup.note
                )
                expense.id = id
                importedExpenses.append(expense)
            }
            self.expenses = importedExpenses
            saveExpenses()
            NSLog("✅ Расходы сохранены: \(importedExpenses.count)")
            
            // Импорт доходов
            var importedIncomes: [Income] = []
            for incBackup in backup.incomes {
                var income = Income(
                    amount: incBackup.amount,
                    date: incBackup.date,
                    note: incBackup.note
                )
                income.id = incBackup.id
                importedIncomes.append(income)
            }
            self.incomes = importedIncomes
            saveIncomes()
            NSLog("✅ Доходы сохранены: \(importedIncomes.count)")
            
            NSLog("🎉 ИМПОРТ ЗАВЕРШЁН УСПЕШНО!")
            return true
            
        } catch let error as DecodingError {
            NSLog("❌ ОШИБКА ДЕКОДИРОВАНИЯ:")
            switch error {
            case .keyNotFound(let key, let context):
                NSLog("   Ключ '\(key.stringValue)' не найден")
                NSLog("   Путь: \(context.codingPath)")
                NSLog("   Описание: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                NSLog("   Несоответствие типа: \(type)")
                NSLog("   Путь: \(context.codingPath)")
                NSLog("   Описание: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                NSLog("   Значение не найдено: \(type)")
                NSLog("   Путь: \(context.codingPath)")
            case .dataCorrupted(let context):
                NSLog("   Данные повреждены")
                NSLog("   Описание: \(context.debugDescription)")
            @unknown default:
                NSLog("   Неизвестная ошибка декодирования")
            }
            return false
            
        } catch {
            NSLog("❌ ОБЩАЯ ОШИБКА: \(error.localizedDescription)")
            NSLog("   Детали: \(error)")
            return false
        }
    }
}

// Модель для экспорта
struct BackupData: Codable {
    let version: String
    let exportDate: Date
    let expenses: [ExpenseBackup]
    let incomes: [IncomeBackup]
    let categories: [CategoryBackup]
}

struct ExpenseBackup: Codable {
    let id: String
    let amount: Double
    let categoryId: String
    let date: Date
    let note: String?
    
    // Добавляем custom декодирование
    enum CodingKeys: String, CodingKey {
        case id, amount, categoryId, date, note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
    
    // Оставляем обычный init для экспорта
    init(id: String, amount: Double, categoryId: String, date: Date, note: String?) {
        self.id = id
        self.amount = amount
        self.categoryId = categoryId
        self.date = date
        self.note = note
    }
}

struct IncomeBackup: Codable {
    let id: String
    let amount: Double
    let date: Date
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, date, note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
    
    init(id: String, amount: Double, date: Date, note: String?) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
    }
}

struct CategoryBackup: Codable {
    let id: String
    let name: String
    let color: String
    let icon: String
}
