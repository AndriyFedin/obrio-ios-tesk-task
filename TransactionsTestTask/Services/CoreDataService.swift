//
//  CoreDataService.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import CoreData
import Foundation

final class CoreDataService {
    
    init() {
        persistentContainer = NSPersistentContainer(name: "TransactionsTestTask")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print(error)
                assertionFailure()
            }
        }
        // Ensures that changes in one context are automatically merged into others.
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func totalTransactionCount() async throws -> Int {
        try await viewContext.perform {
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            return try self.viewContext.count(for: fetchRequest)
        }
    }
    
    func transactionsFetchedResultsController(fetchLimit: Int) -> NSFetchedResultsController<Transaction> {
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
    
    func createTransaction(type: TransactionType, amount: Double, category: TransactionCategory, date: Date) async throws {
        // `perform` ensures this block of code runs on the context's private queue.
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
    
    private let persistentContainer: NSPersistentContainer
    
    private var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
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
}
