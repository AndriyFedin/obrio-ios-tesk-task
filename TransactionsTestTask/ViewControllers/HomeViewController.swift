//
//  HomeViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 06.08.2025.
//

import UIKit

final class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    // MARK: - Private
    
    private var tableView: UITableView = .init()
    
    private var transactions: [TransactionDTO] = [
        .init(icon: nil, category: "Taxi", time: "Today", amount: 0.001, currency: "BTC"),
        .init(icon: nil, category: "Groceries", time: "Yesterday", amount: 0.002, currency: "BTC")
    ]
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.self.description())
        
        tableView.delegate = self
        tableView.dataSource = self
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
