//
//  HomeViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 06.08.2025.
//

import UIKit
import Combine

final class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Wallet"
        
        setupTableView()
        setupBindings()
    }
    
    // MARK: - Private
    
    private var tableView: UITableView = .init()
    private var balanceView: BalanceView? { tableView.tableHeaderView as? BalanceView }
    
    private var cancellables: Set<AnyCancellable> = []
    
    private lazy var addFundsViewController = AddFundsViewController()
    
    private var transactions: [TransactionDTO] = [
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC"),
    ]
    
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
    
    private func setupBindings() {
        balanceView?.addBalanceRequested.sink { [weak self] in
            self?.showAddFunds($0)
        }.store(in: &cancellables)
        
        balanceView?.addTransactionRequested.sink { [weak self] in
            let addTransactionViewController = AddTransactionViewController()
            let navigationController = UINavigationController.init(rootViewController: addTransactionViewController)
            self?.present(navigationController, animated: true)
        }.store(in: &cancellables)
        
        addFundsViewController.addfunds.sink { [weak self] in
            print("add \($0) BTC")
            self?.addFundsViewController.dismiss(animated: true)
            self?.addFundsViewController.clearInput() // TODO: change to clear after successful addition
        }.store(in: &cancellables)
        
        // TODO: move this to view model
        ServicesAssembler.bitcoinRateService.ratePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.balanceView?.updateRate(String(format: "%.2f", rate))
                print("rate view updated to: \(rate)")
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
}

// MARK: - UITableView related extensions

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.self.description(), for: indexPath) as? TransactionCell else {
            fatalError("Unable to dequeue TransactionCell.")
        }
        
        let transaction = transactions[indexPath.row]
        cell.configure(with: transaction)
        
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
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
