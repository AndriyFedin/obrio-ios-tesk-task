//
//  TransactionCell.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 06.08.2025.
//

import UIKit

class TransactionCell: UITableViewCell {
    
    func configure(with transaction: TransactionDTO) {
        var config = TransactionContentConfiguration()
        
        config.icon = transaction.icon
        config.title = transaction.category
        config.subtitle = transaction.subtitle
        config.value = "\(transaction.formattedAmount) \(transaction.currency)"
        
        switch transaction.category {
        case "Taxi":
            config.iconBackgroundColor = .systemBlue.withAlphaComponent(0.2)
        case "Restaurant":
            config.iconBackgroundColor = .systemPurple.withAlphaComponent(0.2)
        default:
            config.iconBackgroundColor = .systemGray4
        }
        config.valueColor = transaction.amount < 0 ? .systemRed : .systemGreen
        
        self.contentConfiguration = config
    }
}

struct TransactionDTO {
    let icon: UIImage?
    let category: String
    let time: String
    let amount: Double
    let currency: String
    
    var subtitle: String {
        "\(category) - \(time)"
    }
    
    var formattedAmount: String {
        String(format: "%g", amount)
    }
}
