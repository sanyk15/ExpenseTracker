import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isDarkMode = false
    @State private var currency = "₽"
    @State private var showNotifications = true
    @State private var defaultCategory = "Еда"
    @State private var showAnimation = true
    
    let currencies = ["₽", "$", "€", "£", "¥"]
    let categories = ["Еда", "Транспорт", "Развлечения", "Здоровье", "Прочее"]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Theme Section
                Section("Оформление") {
                    Toggle("Тёмная тема", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _ in
                            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
                            NotificationCenter.default.post(name: NSNotification.Name("themeChanged"), object: nil)
                        }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onAppear {
            isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        }
    }
}
