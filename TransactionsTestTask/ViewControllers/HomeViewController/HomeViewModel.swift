//
//  HomeViewModel.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

import CoreData
import UIKit
import Combine

final class HomeViewModel: NSObject {

    var totalTransactionsCount: Int = 0
    var reloadPublisher: AnyPublisher<Void, Never> { reloadSubject.eraseToAnyPublisher() }
    var beginUpdatesPublisher: AnyPublisher<Void, Never> { beginUpdatesSubject.eraseToAnyPublisher() }
    var endUpdatesPublisher: AnyPublisher<Void, Never> { endUpdatesSubject.eraseToAnyPublisher() }
    var insertRowPublisher: AnyPublisher<IndexPath, Never> { insertRowSubject.eraseToAnyPublisher() }
    var insertSectionPublisher: AnyPublisher<Int, Never> { insertSectionSubject.eraseToAnyPublisher() }
    var ratePublisher: AnyPublisher<Double, Never> { ServicesAssembler.bitcoinRateService.ratePublisher }
    
    var displayingObjectsCount: Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func sectionCount() -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func rowCount(in section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func transactionDTO(at indexPath: IndexPath) -> TransactionDTO {
        let transaction = fetchedResultsController.object(at: indexPath)
        return makeTransactionDTO(from: transaction)
    }
    
    func addDemoData() {
        Task {
            await self.coreDataService.addDemoData()
        }
    }
    
    func fetchData() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure()
        }
    }
    
    func calculateBalance() async -> Double {
        do {
            return try await coreDataService.calculateBalance()
        } catch {
            print("Failed to calculate balance: \(error)")
            return 0
        }
    }
    
    func refreshTotalTransactionsCount() async {
        totalTransactions = (try? await coreDataService.totalTransactionCount()) ?? 0
    }
    
    func nameForSection(at index: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[index] else {
            return nil
        }
        
        return format(dateString: sectionInfo.name)
    }
    
    func loadMoreIfNeeded() {
        guard !isLoadingMore,
              let fetchedCount = fetchedResultsController.fetchedObjects?.count,
              fetchedCount < totalTransactions else {
            return
        }
        loadNextPage()
    }
    
    // MARK: - Private
    
    private let pageSize = 20
    private var isLoadingMore = false
    private var totalTransactions = 0
    
    private let reloadSubject: PassthroughSubject<Void, Never> = .init()
    private let beginUpdatesSubject: PassthroughSubject<Void, Never> = .init()
    private let endUpdatesSubject: PassthroughSubject<Void, Never> = .init()
    private let insertRowSubject: PassthroughSubject<IndexPath, Never> = .init()
    private let insertSectionSubject: PassthroughSubject<Int, Never> = .init()
    
    private var coreDataService: CoreDataService = ServicesAssembler.coreDataService
    private lazy var fetchedResultsController: NSFetchedResultsController<Transaction> = {
        let controller = coreDataService.transactionsFetchedResultsController(fetchLimit: pageSize)
        controller.delegate = self
        return controller
    }()
    
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
        
        let currentCount = fetchedResultsController.fetchedObjects?.count ?? 0
        let newLimit = currentCount + pageSize
        
        let fetchRequest = fetchedResultsController.fetchRequest
        fetchRequest.fetchLimit = newLimit
        
        do {
            print("Loading next page: \(newLimit)")
            try fetchedResultsController.performFetch()
            reloadSubject.send()
        } catch {
            print("Failed to fetch next page: \(error)")
        }
        
        isLoadingMore = false
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension HomeViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        beginUpdatesSubject.send()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertRowSubject.send(newIndexPath)
            }
        default:
            reloadSubject.send()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            insertSectionSubject.send(sectionIndex)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task {
            await refreshTotalTransactionsCount()
            endUpdatesSubject.send()
        }
    }
}
