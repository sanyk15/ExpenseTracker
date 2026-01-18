import Foundation

struct Expense: Identifiable, Codable, Equatable {
    var id = UUID()
    var amount: Double
    var category: Category
    var date: Date
    var note: String?
    
    // Для удобства
    var formattedAmount: String {
        String(format: "%.2f ₽", amount)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // Реализация Equatable
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        lhs.id == rhs.id &&
        lhs.amount == rhs.amount &&
        lhs.category == rhs.category &&
        lhs.date == rhs.date &&
        lhs.note == rhs.note
    }
}
