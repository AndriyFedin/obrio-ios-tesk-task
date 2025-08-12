//
//  AddFundsViewModel.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

final class AddFundsViewModel {
    
    func addFunds(_ amountString: String) async throws {
        let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        try await coreDataService.createTransaction(
            type: .topUp,
            amount: amount,
            category: .other,
            date: .now
        )
    }
    
    // MARK: - Private
    
    let coreDataService = ServicesAssembler.coreDataService
}
