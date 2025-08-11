//
//  TransactionCategory.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

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
