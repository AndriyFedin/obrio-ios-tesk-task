//
//  AddTransactionViewModel.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

final class AddTransactionViewModel {
    
    init(transactionCreator: TransactionCreator) {
        self.transactionCreator = transactionCreator
    }
    
    func createTransaction(amount: String, category: TransactionCategory) async throws {
        try await transactionCreator.createTransaction(
            type: .expense,
            amount: Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            category: category,
            date: .now
        )
    }
    
    // MARK: - Private
    
    private let transactionCreator: TransactionCreator
}
