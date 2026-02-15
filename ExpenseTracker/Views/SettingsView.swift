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
