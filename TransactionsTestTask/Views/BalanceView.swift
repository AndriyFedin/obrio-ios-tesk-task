//
//  BalanceView.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 07.08.2025.
//

import UIKit
import Combine

final class BalanceView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var addBalanceRequested: AnyPublisher<UIView, Never> { addBalanceRequestedSubject.eraseToAnyPublisher() }
    var addTransactionRequested: AnyPublisher<Void, Never> { addTransactionRequestedSubject.eraseToAnyPublisher() }
    
    // MARK: - Private
    
    private let titleLabel: UILabel = .init()
    private let balanceLabel: UILabel = .init()
    private let topUpButton: UIButton = .init(type: .roundedRect)
    
    private let transactionsLabel: UILabel = .init()
    private let addExpenseButton: UIButton = .init(type: .roundedRect)
    
    private let addBalanceRequestedSubject: PassthroughSubject<UIView, Never> = .init()
    private let addTransactionRequestedSubject: PassthroughSubject<Void, Never> = .init()
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        
        setupSubviews()
        setupLayout()
    }
    
    private func setupSubviews() {
        titleLabel.text = "Current balance"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .tertiaryLabel
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let roundedFontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .extraLargeTitle)
            .withDesign(.rounded)
        let roundedFont = UIFont(descriptor: roundedFontDescriptor!, size: 0)
        balanceLabel.text = "1.25 BTC"
        balanceLabel.font = roundedFont
        balanceLabel.setContentHuggingPriority(.required, for: .vertical)
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        topUpButton.setTitle("Top Up", for: .normal)
        topUpButton.addTarget(self, action: #selector(handleTopUpButtonTap), for: .touchUpInside)
        topUpButton.setContentHuggingPriority(.required, for: .vertical)
        topUpButton.configuration = .tinted()
        topUpButton.translatesAutoresizingMaskIntoConstraints = false
        
        transactionsLabel.text = "Transactions"
        transactionsLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        transactionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addExpenseButton.setTitle("Add Expense", for: .normal)
        addExpenseButton.addTarget(self, action: #selector(handleAddExpenseButtonTap), for: .touchUpInside)
        addExpenseButton.setContentHuggingPriority(.required, for: .vertical)
        addExpenseButton.setContentCompressionResistancePriority(.required, for: .vertical)
        addExpenseButton.configuration = .filled()
        addExpenseButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLayout() {
        let currencyView: CurrencyView = .init()
        currencyView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(currencyView)
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, balanceLabel, topUpButton])
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .center
        
        vStack.spacing = 8
        
        addSubview(vStack)
        
        let bottomContainer: UIView = .init()
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(transactionsLabel)
        bottomContainer.addSubview(addExpenseButton)
        addSubview(bottomContainer)
        
        let constraints = [
            currencyView.topAnchor.constraint(equalTo: topAnchor),
            currencyView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            vStack.topAnchor.constraint(greaterThanOrEqualTo: currencyView.bottomAnchor),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomContainer.topAnchor, constant: -24),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            transactionsLabel.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
            transactionsLabel.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            
            addExpenseButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
            addExpenseButton.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
            addExpenseButton.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor),
            
            bottomContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            bottomContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc private func handleTopUpButtonTap() {
        addBalanceRequestedSubject.send(topUpButton)
    }
    
    @objc private func handleAddExpenseButtonTap() {
        addTransactionRequestedSubject.send()
    }
}
