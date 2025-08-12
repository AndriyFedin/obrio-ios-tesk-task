//
//  BitcoinRateModels.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 09.08.2025.
//

import Foundation

protocol RateCache {
    func save(rate: Double)
    func load() -> Double?
}

struct UserDefaultsRateCache: RateCache {
    private let cacheKey = "cachedBitcoinRate"
    
    func save(rate: Double) {
        UserDefaults.standard.set(rate, forKey: cacheKey)
    }
    
    func load() -> Double? {
        let value = UserDefaults.standard.double(forKey: cacheKey)
        return value == 0 ? nil : value
    }
}
