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
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Wallet"
        
        setupSubviews()
        setupBindings()
        
        performInitialFetch()
        
        Task {
            await updateBalanceLabel()
        }
    }
    
    // MARK: - Private
    
    private let tableView: UITableView = .init()
    private var balanceView: BalanceView? { tableView.tableHeaderView as? BalanceView }
    private let emptyView: HomeEmptyView = .init()
    
    private let viewModel: HomeViewModel
    
    private var cancellables: Set<AnyCancellable> = []
    
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
                self?.viewModel.handleAddTransactionAction()
            }.store(in: &cancellables)
        
        viewModel.ratePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.balanceView?.updateRate(String(format: "%.2f", rate))
            }.store(in: &cancellables)
        
        emptyView.actionHandler
            .sink { [weak viewModel] in
                viewModel?.addDemoData()
            }.store(in: &cancellables)
        
        viewModel.reloadPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView] in
                tableView?.reloadData()
            }.store(in: &cancellables)
        
        viewModel.beginUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView] in
                tableView?.beginUpdates()
            }.store(in: &cancellables)
        
        viewModel.endUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.tableView.endUpdates()
                self.updateEmptyViewVisibility()
                Task {
                    await self.updateBalanceLabel()
                }
            }.store(in: &cancellables)
        
        viewModel.insertRowPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView] indexPath in
                tableView?.insertRows(at: [indexPath], with: .automatic)
            }.store(in: &cancellables)
        
        viewModel.insertSectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView] section in
                tableView?.insertSections(IndexSet(integer: section), with: .automatic)
            }.store(in: &cancellables)
    }
    
    private func showAddFunds(_ sender: UIView) {
        viewModel.handleAddFundsAction(from: sender)
    }
    
    private func performInitialFetch() {
        viewModel.fetchData()
        tableView.reloadData()
        updateEmptyViewVisibility()
        refreshTotalTransactionsCount()
    }
    
    private func updateBalanceLabel() async {
        let balance = await viewModel.calculateBalance()
        await MainActor.run {
            balanceView?.setBalance(String(format: "%.2f BTC", balance))
        }
    }
    
    private func updateEmptyViewVisibility() {
        emptyView.isHidden = viewModel.displayingObjectsCount != 0
    }
    
    private func refreshTotalTransactionsCount() {
        Task {
            await viewModel.refreshTotalTransactionsCount()
        }
    }
}

// MARK: - UITableView related extensions

extension HomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sectionCount()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rowCount(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TransactionCell.self.description(),
            for: indexPath
        ) as? TransactionCell else {
            fatalError("Unable to dequeue TransactionCell.")
        }
        
        let transactionDTO = viewModel.transactionDTO(at: indexPath)
        cell.configure(with: transactionDTO)
        
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.nameForSection(at: section)
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
            viewModel.loadMoreIfNeeded()
        }
    }
}

