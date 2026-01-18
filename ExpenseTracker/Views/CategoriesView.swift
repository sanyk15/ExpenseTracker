import SwiftUI

struct CategoriesView: View {
    var viewModel: ExpenseViewModel
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "📌"
    @State private var newCategoryColor = "#CCCCCC"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.categories) { category in
                    NavigationLink(destination: CategoryEditView(viewModel: viewModel, category: category)) {
                        HStack {
                            Text(category.icon)
                                .font(.title2)
                            Text(category.name)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteCategory(category)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveCategory)
            }
            .navigationTitle("Категории")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                NavigationStack {
                    Form {
                        TextField("Название", text: $newCategoryName)
                        TextField("Эмодзи", text: $newCategoryIcon)
                    }
                    .navigationTitle("Новая категория")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Сохранить") {
                                let newCategory = Category(
                                    name: newCategoryName,
                                    color: newCategoryColor,
                                    icon: newCategoryIcon
                                )
                                viewModel.addCategory(newCategory)
                                newCategoryName = ""
                                newCategoryIcon = "📌"
                                showAddCategory = false
                            }
                            .disabled(newCategoryName.isEmpty)
                        }
                    }
                }
            }
        }
    }
    
    private func moveCategory(from source: IndexSet, to destination: Int) {
        viewModel.categories.move(fromOffsets: source, toOffset: destination)
        viewModel.saveCategories()
    }
}
