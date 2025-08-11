//
//  HomeViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 06.08.2025.
//

import UIKit
import Combine
import CoreData

final class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Wallet"
        
        setupSubviews()
        setupBindings()
        
        
        // TODO: move this out (to the view model?)
        performInitialFetch()
        
        Task {
            await updateBalanceLabel()
        }
    }
    
    // MARK: - Private
    
    private let tableView: UITableView = .init()
    private var balanceView: BalanceView? { tableView.tableHeaderView as? BalanceView }
    private let emptyView: HomeEmptyView = .init()
    
    private var cancellables: Set<AnyCancellable> = []
    
    private lazy var addFundsViewController = AddFundsViewController()
    
    private let pageSize = 20
    private var isLoadingMore = false
    private var totalTransactions = 0
    
    private var coreDataService: CoreDataService = ServicesAssembler.coreDataService
    private lazy var fetchedResultsController: NSFetchedResultsController<Transaction> = {
        let controller = coreDataService.transactionsFetchedResultsController(fetchLimit: pageSize)
        controller.delegate = self
        return controller
    }()
    
    private func setupSubviews() {
        setupTableView()
        setupEmptyView()
        setupLayout()
    }
    
    private func setupEmptyView() {
        emptyView.setTitle("No transactions")
        emptyView.setActionTitle("Add demo transactions")
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        let header = BalanceView()
        header.frame.size.height = 200
        tableView.tableHeaderView = header
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            header.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            header.heightAnchor.constraint(equalToConstant: 200)
        ]
        NSLayoutConstraint.activate(constraints)
        
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.self.description())
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupLayout() {
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private func setupBindings() {
        balanceView?.addBalanceRequested
            .sink { [weak self] in
                self?.showAddFunds($0)
            }.store(in: &cancellables)
        
        balanceView?.addTransactionRequested
            .sink { [weak self] in
                let addTransactionViewController = AddTransactionViewController()
                let navigationController = UINavigationController.init(rootViewController: addTransactionViewController)
                self?.present(navigationController, animated: true)
            }.store(in: &cancellables)
        
        addFundsViewController.addfunds
            .sink { [weak self] amountString in
                self?.addFunds(amountString: amountString)
            }
            .store(in: &cancellables)
        
        // TODO: move this to view model
        ServicesAssembler.bitcoinRateService.ratePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.balanceView?.updateRate(String(format: "%.2f", rate))
            }.store(in: &cancellables)
        
        emptyView.actionHandler
            .sink {
                Task {
                    await self.coreDataService.addDemoData()
                }
            }.store(in: &cancellables)
    }
    
    private func showAddFunds(_ sender: UIView) {
        addFundsViewController.preferredContentSize = .init(width: 240, height: 80)
        addFundsViewController.modalPresentationStyle = .popover
        
        let addFundsPresentationController = addFundsViewController.popoverPresentationController
        addFundsPresentationController?.permittedArrowDirections = .up
        addFundsPresentationController?.sourceRect = sender.bounds
        addFundsPresentationController?.sourceView = sender
        addFundsPresentationController?.delegate = self
        
        present(addFundsViewController, animated: true, completion: nil)
    }
    
    // TODO: move this to view model
    private func performInitialFetch() {
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
            updateEmptyViewVisibility()
            refreshTotalTransactionsCount()
        } catch {
            assertionFailure()
        }
    }
    
    // The create method becomes simpler! We don't need to manually refresh.
    private func addFunds(amountString: String) {
        Task {
            do {
                let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
                try await coreDataService.createTransaction(
                    type: .topUp,
                    amount: amount,
                    category: .other,
                    date: .now
                )
                addFundsViewController.dismiss(animated: true)
                addFundsViewController.clearInput()

            } catch {
                print(error)
            }
        }
    }
    
    private func updateBalanceLabel() async {
        do {
            let balance = try await coreDataService.calculateBalance()
            await MainActor.run {
                balanceView?.setBalance(String(format: "%.2f BTC", balance))
            }
        } catch {
            print("Failed to calculate balance: \(error)")
        }
    }
    
    private func updateEmptyViewVisibility() {
        emptyView.isHidden = !(fetchedResultsController.fetchedObjects?.isEmpty ?? true)
    }
    
    private func refreshTotalTransactionsCount() {
        Task {
            self.totalTransactions = (try? await coreDataService.totalTransactionCount()) ?? 0
        }
    }
}

// MARK: - UITableView related extensions

extension HomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.self.description(), for: indexPath) as? TransactionCell else {
            fatalError("Unable to dequeue TransactionCell.")
        }
        
        let transaction = fetchedResultsController.object(at: indexPath)
        let transactionDTO = makeTransactionDTO(from: transaction)
        cell.configure(with: transactionDTO)
        
        return cell
    }
    
    private func transactionDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
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
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Get the section information from the FRC
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return nil
        }
        
        return format(dateString: sectionInfo.name)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height - 500 {
            // Guard against multiple loads and fetching beyond the total count
            guard !isLoadingMore,
                  let fetchedCount = fetchedResultsController.fetchedObjects?.count,
                  fetchedCount < totalTransactions else {
                return
            }
            loadNextPage()
        }
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
    
    private func loadNextPage() {
        print("loading triggered")
        isLoadingMore = true
        
        let currentCount = fetchedResultsController.fetchedObjects?.count ?? 0
        let newLimit = currentCount + pageSize
        
        let fetchRequest = fetchedResultsController.fetchRequest
        fetchRequest.fetchLimit = newLimit
        
        do {
            try fetchedResultsController.performFetch()
            self.tableView.reloadData()
        } catch {
            print("Failed to fetch next page: \(error)")
        }
        
        isLoadingMore = false
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension HomeViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none // Make sure it always looks like a pupup
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension HomeViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        default:
            tableView.reloadData()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateEmptyViewVisibility()
        refreshTotalTransactionsCount()
        Task {
            await updateBalanceLabel()
        }
    }
}
