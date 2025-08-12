//
//  AddFundsViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 08.08.2025.
//

import UIKit
import Combine

final class AddFundsViewController: UIViewController {
    
    init(viewModel: AddFundsViewModel) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    func clearInput() {
        textField.text = ""
    }
   
    // MARK: - Private
    
    private let textField: UITextField = .init()
    private let addButton: UIButton = .init(type: .system)
    private let addButtonContainer: UIView = .init()
        
    private let viewModel: AddFundsViewModel
    
    private func setup() {
        view.translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
        setupLayout()
    }
    
    private func setupSubviews() {
        let roundedFontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded)
        let roundedFont = UIFont(descriptor: roundedFontDescriptor!, size: 0)
        textField.font = roundedFont
        textField.keyboardType = .decimalPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter amount"
        textField.insetsLayoutMarginsFromSafeArea = false
        textField.inputAccessoryView = addButtonContainer
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.configuration = .filled()
        addButton.addAction(UIAction { [weak self] _ in
            self?.handleAddFundsTap()
        }, for: .touchUpInside)
        
        addButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        addButtonContainer.backgroundColor = .systemGroupedBackground
    }
    
    private func setupLayout() {
        view.addSubview(textField)
        NSLayoutConstraint.activate(
            textField.constraintsForAnchoringTo(boundsOf: view, withInsets: .init(top: 30, left: 16, bottom: 16, right: 16))
        )
        
        addButtonContainer.addSubview(addButton)
        NSLayoutConstraint.activate(
            addButton.constraintsForAnchoringTo(boundsOf: addButtonContainer, withInset: 8)
        )
    }
    
    private func handleAddFundsTap() {
        guard let fundsString = textField.text else { return }
        Task {
            do {
                try await viewModel.addFunds(fundsString)
                clearInput()
                dismiss(animated: true)
            } catch {
                print(error)
                assertionFailure()
            }
        }
    }
}

