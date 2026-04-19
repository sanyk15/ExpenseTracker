import SwiftUI

struct ContentView: View {
    @State var viewModel = ExpenseViewModel()
    @State var showAddExpense = false
    @State var selectedDate = Date()
    @State private var isDarkMode = false

    var body: some View {
        TabView {
            // Tab 1: Today's expenses
            NavigationStack {
                VStack {
                    DatePicker(
                        "Дата",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    .padding()
                    
                    let todayExpenses = viewModel.getExpensesForDate(selectedDate)
                    
                    if todayExpenses.isEmpty {
                        VStack(spacing: 16) {
                            Text("🎉")
                                .font(.system(size: 60))
                            Text("Бесплатный день!")
                                .font(.headline)
                            Text("Поздравляем! Сегодня без расходов")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        List {
                            ForEach(todayExpenses) { expense in
                                NavigationLink(destination: EditExpenseView(viewModel: viewModel, expense: expense)) {
                                    HStack {
                                        Text(expense.category.icon)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading) {
                                            Text(expense.category.name)
                                                .font(.headline)
                                            if let note = expense.note, !note.isEmpty {
                                                Text(note)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text(expense.formattedAmount)
                                            .font(.headline)
                                            .foregroundColor(.red)
                                    }
                                    .foregroundColor(.primary)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteExpense(expense)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Итого:")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.2f ₽", viewModel.getTotalForPeriod(todayExpenses)))
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Button(action: {
                            viewModel.copyExpensesToClipboard(expenses: todayExpenses, reportDate: selectedDate)
                        }) {
                            Label("Копировать список", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding()
                    }
                }
                .navigationTitle("Расходы")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                            NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                                    Image(systemName: "gearshape.fill")
                                }
                            }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddExpense = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .tabItem {
                Label("Расходы", systemImage: "creditcard")
            }
            
            // Tab 2: Incomes
            IncomeView(viewModel: viewModel)
                .tabItem {
                    Label("Доходы", systemImage: "banknote")
                }
            
            // Tab 3: Statistics + Balance (UNIFIED)
            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar")
                }
            
            // Tab 4: Limits
            BudgetView(viewModel: viewModel)
                .tabItem {
                    Label("Лимиты", systemImage: "gauge.with.dots.needle.33percent")
                }
            
            // Tab 5: Categories
            CategoriesView(viewModel: viewModel)
                .tabItem {
                    Label("Категории", systemImage: "list.bullet")
                }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
                .sheet(isPresented: $showAddExpense) {
                    NavigationStack {
                        AddExpenseView(viewModel: viewModel, isPresented: $showAddExpense, selectedDate: $selectedDate)
                    }
                }
                .onAppear {
                    isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
                    NotificationCenter.default.addObserver(
                        forName: NSNotification.Name("themeChanged"),
                        object: nil,
                        queue: .main
                    ) { _ in
                        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
                    }
                }
    }
}
