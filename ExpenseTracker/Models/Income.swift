import Foundation

struct Income: Identifiable, Codable {
    var id: String = UUID().uuidString
    var amount: Double
    var date: Date
    var note: String?
    
    var formattedAmount: String {
        String(format: "%.2f ₽", amount)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}
