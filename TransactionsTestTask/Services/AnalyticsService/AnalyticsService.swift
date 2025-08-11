//
//  AnalyticsService.swift
//  TransactionsTestTask
//
//

import Foundation

/// Analytics Service is used for events logging
/// The list of reasonable events is up to you
/// It should be possible not only to track events but to get it from the service
/// The minimal needed filters are: event name and date range
/// The service should be covered by unit tests
protocol AnalyticsService: AnyObject {
    
    func trackEvent(name: String, parameters: [String: String], date: Date) async
    func events(named name: String?, between startDate: Date, and endDate: Date) async -> [AnalyticsEvent]
}

extension AnalyticsService {
    func trackEvent(name: String, parameters: [String: String], date: Date = .now) async {
        await trackEvent(name: name, parameters: parameters, date: date)
    }
}

actor AnalyticsServiceImpl {
    
    private var events: [AnalyticsEvent] = []
    
    // MARK: - Init
    
    init() {
        
    }
}

extension AnalyticsServiceImpl: AnalyticsService {
    
    func trackEvent(name: String, parameters: [String: String], date: Date) {
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            date: date
        )
        
        events.append(event)
    }
    
    func events(named name: String?, between startDate: Date, and endDate: Date) -> [AnalyticsEvent] {
        let dateFilteredEvents = events.filter { event in
            event.date >= startDate && event.date <= endDate
        }
        
        if let name {
            return dateFilteredEvents.filter { $0.name == name }
        } else {
            return dateFilteredEvents
        }
    }
}
