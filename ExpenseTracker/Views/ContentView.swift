import SwiftUI

struct ContentView: View {
    @State var viewModel = ExpenseViewModel()
    @State var showAddExpense = false
    @State var showCategories = false
    @State var selectedDate = Date()
    
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
                    .padding()
                    
                    let todayExpenses = viewModel.getExpensesForDate(selectedDate)
                    
                    if todayExpenses.isEmpty {
                        VStack {
                            Text("Нет расходов")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("за этот день")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        List {
                            ForEach(todayExpenses) { expense in
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
                            viewModel.copyExpensesToClipboard(todayExpenses)
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
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddExpense = true }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .tabItem {
                Label("Сегодня", systemImage: "calendar")
            }
            
            // Tab 2: Statistics
            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar")
                }
            
            // Tab 3: Categories
            CategoriesView(viewModel: viewModel)
                .tabItem {
                    Label("Категории", systemImage: "list.bullet")
                }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(viewModel: viewModel, isPresented: $showAddExpense)
        }
    }
}
