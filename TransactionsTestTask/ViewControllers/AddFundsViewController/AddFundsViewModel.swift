//
//  AddFundsViewModel.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

final class AddFundsViewModel {
    
    init(transactionCreator: TransactionCreator) {
        self.transactionCreator = transactionCreator
    }
    
    func addFunds(_ amountString: String) async throws {
        let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        try await transactionCreator.createTransaction(
            type: .topUp,
            amount: amount,
            category: .other,
            date: .now
        )
    }
    
    // MARK: - Private
    
    private let transactionCreator: TransactionCreator
}
