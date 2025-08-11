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
        config.subtitle = transaction.time
        config.value = "\(transaction.amount) \(transaction.currency)"
        config.iconBackgroundColor = transaction.backgroundColor
        config.valueColor = transaction.valueColor
        
        self.contentConfiguration = config
    }
}

struct TransactionDTO {
    let icon: UIImage?
    let category: String
    let type: TransactionType
    let time: String
    let amount: Double
    let currency: String
    let valueColor: UIColor
    let backgroundColor: UIColor
}
