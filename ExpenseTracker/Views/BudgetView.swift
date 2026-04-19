import SwiftUI

struct BudgetView: View {
    var viewModel: ExpenseViewModel

    @State private var selectedDate: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var selectedYear: Int {
        calendar.component(.year, from: selectedDate)
    }

    private var selectedMonth: Int {
        calendar.component(.month, from: selectedDate)
    }

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "LLLL yyyy"
        return f
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Выбор месяца
                HStack {
                    Button {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(10)
                    }

                    Spacer()

                    Text(monthFormatter.string(from: selectedDate).capitalized)
                        .font(.headline)

                    Spacer()

                    Button {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    } label: {
                        Image(systemName: "chevron.right")
                            .padding(10)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.categories) { category in
                            BudgetCategoryRow(
                                category: category,
                                year: selectedYear,
                                month: selectedMonth,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Лимиты")
            .preferredColorScheme(.light)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                            NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                                Image(systemName: "gearshape.fill")
                            }
                        }
            }
        }
    }
}

// MARK: - BudgetCategoryRow

struct BudgetCategoryRow: View {
    let category: Category
    let year: Int
    let month: Int
    var viewModel: ExpenseViewModel

    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    private var currentLimit: Double {
        viewModel.getBudget(categoryId: category.id, year: year, month: month)?.limit ?? 0
    }

    private var spent: Double {
        let expenses = viewModel.getExpensesForCategoryInMonth(category: category, year: year, month: month)
        return expenses.reduce(0) { $0 + $1.amount }
    }

    private var progress: Double {
        guard currentLimit > 0 else { return 0 }
        return min(spent / currentLimit, 1.0)
    }

    private var isOverLimit: Bool {
        currentLimit > 0 && spent > currentLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок категории
            HStack {
                Text(category.icon)
                    .font(.title3)
                Text(category.name)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                if currentLimit > 0 {
                    Text(isOverLimit ? "⚠️ Превышен" : "Лимит: \(String(format: "%.0f ₽", currentLimit))")
                        .font(.caption)
                        .foregroundColor(isOverLimit ? .red : .gray)
                }
            }

            // Прогресс-бар (если лимит задан)
            if currentLimit > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isOverLimit ? Color.red.opacity(0.8) : Color.green.opacity(0.7))
                            .frame(width: geo.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Потрачено: \(String(format: "%.2f ₽", spent))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Остаток: \(String(format: "%.2f ₽", max(currentLimit - spent, 0)))")
                        .font(.caption)
                        .foregroundColor(isOverLimit ? .red : .gray)
                }
            }

            // Поле ввода лимита
            HStack(spacing: 8) {
                TextField("Введите лимит (₽)", text: $inputText)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .padding(8)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(8)

                Button("Сохранить") {
                    if let value = Double(inputText.replacingOccurrences(of: ",", with: ".")) {
                        viewModel.setBudget(categoryId: category.id, year: year, month: month, limit: value)
                        inputText = ""
                        isFocused = false
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(8)
                .foregroundColor(.blue)
                .font(.subheadline)

                // Кнопка удаления — только если лимит задан
                if currentLimit > 0 {
                    Button {
                        viewModel.deleteBudget(categoryId: category.id, year: year, month: month)
                        inputText = ""
                        isFocused = false
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            if currentLimit > 0 {
                inputText = String(format: "%.0f", currentLimit)
            }
        }
        .onChange(of: month) { _ in
            inputText = currentLimit > 0 ? String(format: "%.0f", currentLimit) : ""
        }
        .onChange(of: year) { _ in
            inputText = currentLimit > 0 ? String(format: "%.0f", currentLimit) : ""
        }
    }
}
