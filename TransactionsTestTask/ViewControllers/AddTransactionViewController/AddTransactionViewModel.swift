//
//  AddTransactionViewModel.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

final class AddTransactionViewModel {
    
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
    }
    
    func createTransaction(amount: String, category: TransactionCategory) async throws {
        try await coreDataService.createTransaction(
            type: .expense,
            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            category: category,
            date: .now
        )
    }
    
    // MARK: - Private
    
    private let coreDataService: CoreDataService
}
