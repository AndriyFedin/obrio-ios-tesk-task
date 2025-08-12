//
//  CurrencyView.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 07.08.2025.
//

import UIKit

final class RateView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func setValue(_ value: String) {
        valueLabel.text = value
    }
    
    // MARK: - Private
    
    private var titleLabel: UILabel = .init()
    private var valueLabel: UILabel = .init()
    
    private func setup() {
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        
        valueLabel.font = .preferredFont(forTextStyle: .callout)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.setContentHuggingPriority(.required, for: .vertical)
        
        let vStack: UIStackView = .init(arrangedSubviews: [titleLabel, valueLabel])
        vStack.axis = .vertical
        vStack.distribution = .fillProportionally
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
