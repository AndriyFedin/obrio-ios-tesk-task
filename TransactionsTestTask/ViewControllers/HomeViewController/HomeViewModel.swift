//
//  HomeViewModel.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

import CoreData
import UIKit
import Combine

final class HomeViewModel {
    
    enum HomeDataUpdate: Equatable {
        case reload
        case beginUpdates
        case endUpdates
        case insertRow(at: IndexPath)
        case insertSection(at: Int)
    }
    
    init(dataSource: TransactionDataSource, rateService: BitcoinRateService) {
        self.dataSource = dataSource
        self.rateService = rateService
        setupSubscriptions()
    }

    var ratePublisher: AnyPublisher<Double, Never> { rateService.ratePublisher }
    var dataUpdatedPublisher: AnyPublisher<HomeDataUpdate, Never> { dataUpdateSubject.eraseToAnyPublisher() }
    
    var displayingObjectsCount: Int {
        dataSource.displayingObjectsCount
    }
    
    func sectionCount() -> Int {
        dataSource.numberOfSections()
    }
    
    func rowCount(in section: Int) -> Int {
        dataSource.numberOfObjects(in: section)
    }
    
    func transactionDTO(at indexPath: IndexPath) -> TransactionDTO {
        let transaction = dataSource.object(at: indexPath)
        return makeTransactionDTO(from: transaction)
    }
    
    func addDemoData() {
        Task {
            await self.dataSource.addDemoData()
        }
    }
    
    func fetchData() {
        dataSource.performFetch()
        Task {
            await refreshTotalTransactionsCount()
        }
    }
    
    func calculateBalance() async -> Double {
        do {
            return try await dataSource.calculateBalance()
        } catch {
            print("Failed to calculate balance: \(error)")
            return 0
        }
    }
    
    func nameForSection(at index: Int) -> String? {
        dataSource.nameForSection(at: index).map { format(dateString: $0) }
    }
    
    func loadMoreIfNeeded() {
        guard !isLoadingMore, displayingObjectsCount < totalTransactions else {
            return
        }
        loadNextPage()
    }
    
    func handleAddFundsAction(from sender: UIView) {
        router?.showAddFunds(from: sender)
    }
    
    func handleAddTransactionAction() {
        router?.showAddTransaction()
    }
    
    func setRouter(_ router: MainRouter) {
        self.router = router
    }
    
    // MARK: - Private
    
    private var isLoadingMore = false
    private var totalTransactions = 0
    
    private let dataUpdateSubject: PassthroughSubject<HomeDataUpdate, Never> = .init()
    
    private var cancellable: AnyCancellable?
    
    private let rateService: BitcoinRateService
    private let dataSource: TransactionDataSource
    private weak var router: MainRouter?
    
    private func setupSubscriptions() {
        cancellable = dataSource.contentUpdatePublisher
            .map { $0.homeDataUpdate }
            .sink { [weak self] update in
                Task {
                    await self?.handleDataUpdate(update)
                    self?.dataUpdateSubject.send(update)
                }
            }
    }
    
    private func transactionDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
    
    private func format(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .complete, time: .omitted)
        }
    }
    
    private func makeTransactionDTO(from transaction: Transaction) -> TransactionDTO {
        let category = TransactionCategory(rawValue: transaction.categoryRaw ?? "") ?? .other
        var amount = transaction.amount
        let type = TransactionType(rawValue: transaction.type ?? "") ?? .unknown
        if type == .expense {
            amount *= -1
        }
        let backghoundColor: UIColor
        switch category {
        case .groceries:
            backghoundColor = .systemPink.withAlphaComponent(0.2)
        case .taxi:
            backghoundColor = .systemYellow.withAlphaComponent(0.2)
        case .electronics:
            backghoundColor = .systemBlue.withAlphaComponent(0.2)
        case .restaurant:
            backghoundColor = .systemPurple.withAlphaComponent(0.2)
        case .other:
            backghoundColor = .systemGreen.withAlphaComponent(0.2)
        }
        let valueColor: UIColor = type == .expense ? .systemRed : .systemGreen
        
        return TransactionDTO(
            icon: nil,
            category: category.title,
            type: type,
            time: transactionDateString(from: transaction.date ?? .now),
            amount: amount,
            currency: "BTC",
            valueColor: valueColor,
            backgroundColor: backghoundColor
        )
    }
    
    private func loadNextPage() {
        isLoadingMore = true
        
        dataSource.loadNextPage()
        dataUpdateSubject.send(.reload)
        
        isLoadingMore = false
    }
    
    private func refreshTotalTransactionsCount() async {
        totalTransactions = (try? await dataSource.totalTransactionCount()) ?? 0
    }
    
    private func handleDataUpdate(_ update: HomeDataUpdate) async {
        if update == .endUpdates {
            await refreshTotalTransactionsCount()
        }
    }
}

private extension TransactionDataSourceUpdate {
    var homeDataUpdate: HomeViewModel.HomeDataUpdate {
        switch self {
        case .reload:
            .reload
        case .beginUpdates:
            .beginUpdates
        case .endUpdates:
            .endUpdates
        case let .insertRow(row):
            .insertRow(at: row)
        case let .insertSection(section):
            .insertSection(at: section)
        }
    }
}
