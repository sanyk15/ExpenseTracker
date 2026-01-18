import Foundation

struct Category: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var name: String
    var color: String // hex color, например "#FF5733"
    var icon: String // emoji, например "🍔"
}

// Дефолтные категории
let defaultCategories = [
    Category(name: "Еда", color: "#FF6B6B", icon: "🍔"),
    Category(name: "Транспорт", color: "#4ECDC4", icon: "🚗"),
    Category(name: "Развлечения", color: "#FFE66D", icon: "🎮"),
    Category(name: "Покупки", color: "#95E1D3", icon: "🛍️"),
    Category(name: "Здоровье", color: "#C7CEEA", icon: "💊"),
    Category(name: "Коммунальные", color: "#AA96DA", icon: "🏠"),
    Category(name: "Прочее", color: "#CCCCCC", icon: "📌")
]
