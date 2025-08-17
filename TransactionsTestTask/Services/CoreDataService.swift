//
//  CoreDataService.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import CoreData
import Foundation
import Combine

protocol TransactionCreator {
    func createTransaction(type: TransactionType, amount: Double, category: TransactionCategory, date: Date) async throws
}

protocol TransactionDataSource: NSObject {
    var displayingObjectsCount: Int { get }
    var contentUpdatePublisher: AnyPublisher<TransactionDataSourceUpdate, Never> { get }
    
    func numberOfSections() -> Int
    func numberOfObjects(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> Transaction
    func performFetch()
    func nameForSection(at index: Int) -> String?
    func totalTransactionCount() async throws -> Int
    func loadNextPage()
    func calculateBalance() async throws -> Double
    func addDemoData() async
}

enum TransactionDataSourceUpdate {
    case reload
    case beginUpdates
    case endUpdates
    case insertRow(at: IndexPath)
    case insertSection(at: Int)
}

final class CoreDataService: NSObject, TransactionDataSource {
    
    var contentUpdatePublisher: AnyPublisher<TransactionDataSourceUpdate, Never> { contentUpdateSubject.eraseToAnyPublisher() }
    
    var displayingObjectsCount: Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "TransactionsTestTask")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print(error)
                assertionFailure()
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        super.init()
    }
    
    func numberOfSections() -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfObjects(in section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func object(at indexPath: IndexPath) -> Transaction {
        fetchedResultsController.object(at: indexPath)
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure()
        }
    }
    
    func nameForSection(at index: Int) -> String? {
        fetchedResultsController.sections?[index].name
    }
    
    func loadNextPage() {
        let currentCount = fetchedResultsController.fetchedObjects?.count ?? 0
        let newLimit = currentCount + pageSize
        
        let fetchRequest = fetchedResultsController.fetchRequest
        fetchRequest.fetchLimit = newLimit
        
        do {
            print("Loading next page: \(newLimit)")
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to fetch next page: \(error)")
        }
    }
    
    func totalTransactionCount() async throws -> Int {
        try await viewContext.perform {
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            return try self.viewContext.count(for: fetchRequest)
        }
    }
    
    func calculateBalance() async throws -> Double {
        try await viewContext.perform {
            let totalIncome = try self.calculateSum(for: .topUp)
            let totalExpenses = try self.calculateSum(for: .expense)
            return totalIncome - totalExpenses
        }
    }

    func addDemoData() async {
        await viewContext.perform {
            do {
                for i in 0..<50 {
                    let newTransaction = Transaction(context: self.viewContext)
                    newTransaction.id = UUID()
                    
                    let dayOffset = i / 2
                    guard let transactionDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
                    
                    newTransaction.date = transactionDate
                    newTransaction.day = Calendar.current.startOfDay(for: transactionDate)
                    
                    let randomType = TransactionType.allCases.randomElement() ?? .expense
                    newTransaction.type = randomType.rawValue
                    
                    if randomType == .topUp {
                        newTransaction.categoryRaw = TransactionCategory.other.rawValue
                    } else {
                        newTransaction.categoryRaw = TransactionCategory.allCases.randomElement()?.rawValue
                    }
                    
                    let randomAmount = Double.random(in: 0.001...3.0)
                    newTransaction.amount = (randomAmount * 100).rounded() / 100
                }
                
                try self.viewContext.save()
                
            } catch {
                print("Failed to add demo data: \(error)")
            }
        }
    }
    
    // MARK: - Private
    private let pageSize: Int = 20
    private let persistentContainer: NSPersistentContainer
    
    private let contentUpdateSubject: PassthroughSubject<TransactionDataSourceUpdate, Never> = .init()
        
    private var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Transaction> = {
        let controller = transactionsFetchedResultsController(fetchLimit: pageSize)
        controller.delegate = self
        return controller
    }()
    
    private func calculateSum(for type: TransactionType) throws -> Double {
        let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest<NSDictionary>(entityName: "Transaction")
        fetchRequest.resultType = .dictionaryResultType
        
        let amountExpression = NSExpression(forKeyPath: \Transaction.amount)
        let sumExpression = NSExpression(forFunction: "sum:", arguments: [amountExpression])
        
        let sumExpressionDescription = NSExpressionDescription()
        sumExpressionDescription.name = "totalAmount"
        sumExpressionDescription.expression = sumExpression
        sumExpressionDescription.expressionResultType = .doubleAttributeType
        
        fetchRequest.propertiesToFetch = [sumExpressionDescription]
        fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue)
        
        let results = try self.viewContext.fetch(fetchRequest)
        
        if let resultDict = results.first, let total = resultDict["totalAmount"] as? Double {
            return total
        }
        
        return 0.0
    }
    
    private func transactionsFetchedResultsController(fetchLimit: Int) -> NSFetchedResultsController<Transaction> {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        let sortByDay = NSSortDescriptor(keyPath: \Transaction.day, ascending: false)
        let sortByDate = NSSortDescriptor(keyPath: \Transaction.date, ascending: false)
        fetchRequest.sortDescriptors = [sortByDay, sortByDate]
        fetchRequest.fetchLimit = fetchLimit
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: #keyPath(Transaction.day),
            cacheName: nil
        )
        return controller
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension CoreDataService: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        contentUpdateSubject.send(.beginUpdates)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                contentUpdateSubject.send(.insertRow(at: newIndexPath))
            }
        default:
            contentUpdateSubject.send(.reload)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            contentUpdateSubject.send(.insertSection(at: sectionIndex))
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task {
            contentUpdateSubject.send(.endUpdates)
        }
    }
}

extension CoreDataService: TransactionCreator {
    func createTransaction(type: TransactionType, amount: Double, category: TransactionCategory, date: Date) async throws {
        try await viewContext.perform {
            let newTransaction = Transaction(context: self.viewContext)
            newTransaction.id = UUID()
            newTransaction.amount = amount
            newTransaction.date = date
            newTransaction.day = Calendar.current.startOfDay(for: date)
            newTransaction.type = type.rawValue
            newTransaction.categoryRaw = category.rawValue
            
            try self.viewContext.save()
        }
    }
}
