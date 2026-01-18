import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    let container = CKContainer.default()
    let database = CKContainer.default().publicCloudDatabase
    
    func syncExpenses(_ expenses: [Expense]) {
        // TODO: Implement CloudKit sync
        // Пока используем только локальное хранилище
    }
    
    func fetchExpenses(completion: @escaping ([Expense]) -> Void) {
        // TODO: Fetch from CloudKit
    }
}
