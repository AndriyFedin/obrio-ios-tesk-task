//
//  AddFundsViewController.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 08.08.2025.
//

import UIKit
import Combine

final class AddFundsViewController: UIViewController {
    
    var addfunds: AnyPublisher<String, Never> {
        addFundsSubject.eraseToAnyPublisher()
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
    
    private let addFundsSubject: PassthroughSubject<String, Never> = .init()
    
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
            guard let self else { return }
            self.addFundsSubject.send(self.textField.text ?? "")
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
            addButton.constraintsForAnchoringTo(boundsOf: addButtonContainer, withInsets: 8)
        )
    }
}

