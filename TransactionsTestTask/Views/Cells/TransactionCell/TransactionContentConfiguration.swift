//
//  TransactionContentConfiguration.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 06.08.2025.
//

import UIKit

struct TransactionContentConfiguration: UIContentConfiguration, Hashable {
    
    static var empty: TransactionContentConfiguration {
        .init()
    }
    
    var icon: UIImage?
    var iconBackgroundColor: UIColor?
    var title: String?
    var subtitle: String?
    var value: String?
    var valueColor: UIColor?
    
    func makeContentView() -> UIView & UIContentView {
        return TransactionContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> TransactionContentConfiguration {
        // customize the appearance based on the state (isSelected, isHighlighted, etc)
        return self
    }
}
