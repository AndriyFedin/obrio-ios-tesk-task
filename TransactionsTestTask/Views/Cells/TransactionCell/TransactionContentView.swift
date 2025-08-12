//
//  TransactionContentView.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 06.08.2025.
//

import UIKit

final class TransactionContentView: UIView, UIContentView {
    
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfig = newValue as? TransactionContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }

    init(configuration: TransactionContentConfiguration) {
        super.init(frame: .zero)
        setupSubviews()
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    private var currentConfiguration: TransactionContentConfiguration = .empty
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let valueLabel = UILabel()

    private func setupSubviews() {
        // vertical stack for the title and subtitle
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 2

        // horizontal stack to hold the icon and the text stack
        let mainStackView = UIStackView(arrangedSubviews: [iconImageView, textStackView, valueLabel])
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .horizontal
        mainStackView.spacing = Constants.UI.mediumSpacing
        mainStackView.alignment = .center
        addSubview(mainStackView)

        textStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        // Constraints
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            iconImageView.widthAnchor.constraint(equalToConstant: 44),
            iconImageView.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func apply(configuration: TransactionContentConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration

        // Icon
        iconImageView.image = configuration.icon
        iconImageView.backgroundColor = configuration.iconBackgroundColor
        iconImageView.tintColor = .white
        iconImageView.contentMode = .center
        iconImageView.layer.cornerRadius = 8

        // Title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.text = configuration.title

        // Subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.text = configuration.subtitle

        // Value
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = configuration.valueColor
        valueLabel.textAlignment = .right
        valueLabel.text = configuration.value
    }
}
