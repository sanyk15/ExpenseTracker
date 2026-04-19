import Foundation

struct CategoryBudget: Identifiable, Codable {
    var id: UUID = UUID()
    var categoryId: UUID
    var year: Int
    var month: Int  // 1-12
    var limit: Double
}
