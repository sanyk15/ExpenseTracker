import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var viewModel: ExpenseViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isDarkMode = false
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDocumentPicker = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var reminderTimeId: UUID = UUID()
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(
        bySettingHour: 21, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var notificationPermissionDenied: Bool = false
    
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
                
                // MARK: - Backup Section
                Section {
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .frame(width: 30)
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Экспортировать данные")
                                    .foregroundColor(.primary)
                                Text("Сохранить резервную копию")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isExporting)
                    
                    Button(action: { showDocumentPicker = true }) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .frame(width: 30)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Импортировать данные")
                                    .foregroundColor(.primary)
                                Text("Загрузить резервную копию")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isImporting)
                } header: {
                    Text("Резервное копирование")
                } footer: {
                    Text("Экспорт создаст JSON файл со всеми данными. Импорт заменит текущие данные на данные из файла.")
                }
                
                // MARK: - Stats Section
                Section("Статистика") {
                    HStack {
                        Text("Расходов")
                        Spacer()
                        Text("\(viewModel.expenses.count)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Доходов")
                        Spacer()
                        Text("\(viewModel.incomes.count)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Категорий")
                        Spacer()
                        Text("\(viewModel.categories.count)")
                            .foregroundColor(.gray)
                    }
                }
                
                // MARK: - Уведомления
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Напоминания")
                            .font(.headline)

                        if notificationPermissionDenied {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.orange)
                                Text("Разрешите уведомления в Настройках iPhone")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        Toggle("Напоминать вносить траты", isOn: $reminderEnabled)
                            .onChange(of: reminderEnabled) { enabled in
                                if enabled {
                                    NotificationManager.shared.requestPermission { granted in
                                        if granted {
                                            let hour = Calendar.current.component(.hour, from: reminderTime)
                                            let minute = Calendar.current.component(.minute, from: reminderTime)
                                            NotificationManager.shared.scheduleDailyReminder(hour: hour, minute: minute)
                                            UserDefaults.standard.set(true, forKey: "reminderEnabled")
                                            notificationPermissionDenied = false
                                        } else {
                                            reminderEnabled = false
                                            notificationPermissionDenied = true
                                        }
                                    }
                                } else {
                                    NotificationManager.shared.cancelDailyReminder()
                                    UserDefaults.standard.set(false, forKey: "reminderEnabled")
                                }
                            }
                        // Пикер ВНУТРИ того же VStack
                        if reminderEnabled {
                            HStack {
                                Text("Время напоминания")
                                    .foregroundColor(.gray)
                                Spacer()
                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .id(reminderTimeId)
                                    .labelsHidden()
                                    .onChange(of: reminderTime) { newTime in
                                        let hour = Calendar.current.component(.hour, from: newTime)
                                        let minute = Calendar.current.component(.minute, from: newTime)
                                        UserDefaults.standard.set(hour, forKey: "reminderHour")
                                        UserDefaults.standard.set(minute, forKey: "reminderMinute")
                                        NotificationManager.shared.scheduleDailyReminder(hour: hour, minute: minute)
                                    }
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .alert("Успешно", isPresented: $showExportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Данные экспортированы")
            }
            .alert("Успешно", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Данные импортированы")
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                exportURL = nil
            }) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onAppear {
            isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
            reminderEnabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
            NotificationManager.shared.checkPermissionStatus { status in
                notificationPermissionDenied = (status == .denied)
            }

            if UserDefaults.standard.object(forKey: "reminderHour") != nil {
                let hour = UserDefaults.standard.integer(forKey: "reminderHour")
                let minute = UserDefaults.standard.integer(forKey: "reminderMinute")
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                if let date = Calendar.current.date(from: components) {
                    reminderTime = date
                    reminderTimeId = UUID()
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        exportURL = nil
        
        // Экспорт в фоновом потоке
        DispatchQueue.global(qos: .userInitiated).async {
            let url = viewModel.exportData()
            
            DispatchQueue.main.async {
                isExporting = false
                
                if let url = url {
                    exportURL = url
                    showShareSheet = true
                } else {
                    errorMessage = "Не удалось экспортировать данные"
                    showError = true
                }
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "URL не найден"
                showError = true
                return
            }
            
            NSLog("🔵 Начинаем импорт в UI")
            isImporting = true
            
            // Импорт в фоновом потоке
            DispatchQueue.global(qos: .userInitiated).async {
                let success = viewModel.importData(from: url)
                
                DispatchQueue.main.async {
                    isImporting = false
                    
                    if success {
                        NSLog("✅ Импорт успешен в UI")
                        showImportSuccess = true
                    } else {
                        NSLog("❌ Импорт не удался в UI")
                        errorMessage = "Не удалось импортировать данные.\nПроверьте формат файла."
                        showError = true
                    }
                }
            }
            
        case .failure(let error):
            NSLog("❌ Ошибка выбора файла: \(error.localizedDescription)")
            errorMessage = "Ошибка: \(error.localizedDescription)"
            showError = true
        }
    }
}

// Share Sheet для iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
