//
//  AnalyticsRateObserver.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import Foundation
import Combine

/// An observer to connect the BitcoinRateService to the AnalyticsService.
final class AnalyticsRateObserver {
    
    init(rateService: BitcoinRateService, analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
        
        cancellable = rateService.ratePublisher
            .sink { [weak self] rate in
                self?.logRateUpdate(rate: rate)
            }
    }
    
    // MARK: - Private
    
    private let analyticsService: AnalyticsService
    private var cancellable: AnyCancellable?
    
    private func logRateUpdate(rate: Double) {
        Task {
            await analyticsService.trackEvent(
                name: "bitcoin_rate_update",
                parameters: ["rate": String(format: "%.2f", rate)]
            )
        }
    }
}
