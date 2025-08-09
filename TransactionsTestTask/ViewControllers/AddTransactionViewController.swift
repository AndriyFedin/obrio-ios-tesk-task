//
//  AddTransactionViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 08.08.2025.
//

import UIKit
import Combine

final class AddTransactionViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - Private
    
    private let amountTitleLabel: UILabel = .init()
    private let amountTextField: UITextField = .init()
    private let categoryTitleLabel: UILabel = .init()
    private let categoryDropDownButton: UIButton = .init()
    private let addButton: UIButton = .init()
    
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
}

enum TransactionCategory: String, CaseIterable {
    case groceries, taxi, electronics, restaurant, other
    
    var imageName: String {
        switch self {
        case .groceries:
            "carrot"
        case .taxi:
            "car.top.door.rear.right.open"
        case .electronics:
            "smartphone"
        case .restaurant:
            "fork.knife"
        case .other:
            "infinity"
        }
    }
    
    var title: String {
        rawValue.capitalized
    }
}
