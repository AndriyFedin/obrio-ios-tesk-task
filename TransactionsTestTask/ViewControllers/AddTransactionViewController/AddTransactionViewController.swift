//
//  AddTransactionViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 08.08.2025.
//

import UIKit
import Combine

final class AddTransactionViewController: UIViewController {
    
    init(viewModel: AddTransactionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        amountTextField.becomeFirstResponder()
    }
    
    // MARK: - Private
    
    private let amountTitleLabel: UILabel = .init()
    private let amountTextField: UITextField = .init()
    private let categoryTitleLabel: UILabel = .init()
    private let categoryDropDownButton: UIButton = .init()
    private let addButton: UIButton = .init()
    
    private let viewModel: AddTransactionViewModel
    
    private let categorySubject: CurrentValueSubject<TransactionCategory, Never> = .init(.other)
    private var cancellables: Set<AnyCancellable> = []
    
    private func setup() {
        title = "Add Transaction"
        view.backgroundColor = .systemBackground
        setupSubviews()
        setupLayout()
        setupBindings()
    }
    
    private func setupSubviews() {
        amountTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        amountTitleLabel.text = "Amount (BTC)"
        amountTitleLabel.font = .preferredFont(forTextStyle: .footnote)
        amountTitleLabel.textColor = .secondaryLabel
        
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.borderStyle = .roundedRect
        amountTextField.backgroundColor = .tertiarySystemBackground
        amountTextField.keyboardType = .decimalPad
        
        categoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryTitleLabel.text = "Category"
        categoryTitleLabel.font = .preferredFont(forTextStyle: .footnote)
        categoryTitleLabel.textColor = .secondaryLabel
        
        categoryDropDownButton.translatesAutoresizingMaskIntoConstraints = false
        categoryDropDownButton.backgroundColor = .tertiarySystemBackground
        categoryDropDownButton.configuration = .gray()
        categoryDropDownButton.configuration?.titleAlignment = .leading
        categoryDropDownButton.configuration?.indicator = .popup
        categoryDropDownButton.contentHorizontalAlignment = .leading
        setupMenu()
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.configuration = .filled()
        addButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.createNewTransaction()
        }, for: .touchUpInside)
    }
    
    private func setupLayout() {
        let amountStack: UIStackView = .init(arrangedSubviews: [amountTitleLabel, amountTextField])
        let categoryStack: UIStackView = .init(arrangedSubviews: [categoryTitleLabel, categoryDropDownButton])
        let mainStack: UIStackView = .init(arrangedSubviews: [amountStack, categoryStack])
        
        [amountStack, categoryStack, mainStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .vertical
            $0.spacing = 8.0
            $0.alignment = .leading
            $0.distribution = .equalSpacing
        }
        mainStack.spacing = 24.0
        
        view.addSubview(mainStack)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            amountTextField.heightAnchor.constraint(equalToConstant: 48.0),
            amountTextField.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            
            categoryDropDownButton.heightAnchor.constraint(equalToConstant: 48.0),
            categoryDropDownButton.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            
            addButton.heightAnchor.constraint(equalToConstant: 48.0),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            addButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16.0),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0)
        ])
    }
    
    private func setupMenu() {
        let actions = TransactionCategory.allCases.map { category in
            UIAction(title: category.title, image: UIImage(systemName: category.imageName)) { [weak self] _ in
                self?.categorySubject.send(category)
            }
        }
        let menu = UIMenu(children: actions)
        
        categoryDropDownButton.menu = menu
        categoryDropDownButton.showsMenuAsPrimaryAction = true
    }
    
    private func setupBindings() {
        categorySubject.sink { [weak self] category in
            self?.categoryDropDownButton.setTitle(category.title, for: .normal)
        }.store(in: &cancellables)
    }
    
    private func createNewTransaction() {
        guard let amount = amountTextField.text else { return }
        Task {
            do {
                try await viewModel.createTransaction(amount: amount, category: categorySubject.value)
                dismiss(animated: true)
            } catch {
                print("Failed to create transaction: \(error)")
            }
        }
    }
}


