//
//  AnalyticsRateObserverTests.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import XCTest
import Combine
@testable import TransactionsTestTask

// MARK: - Test Class

final class AnalyticsRateObserverTests: XCTestCase {
    
    var sut: AnalyticsRateObserver!
    private var mockRateService: MockBitcoinRateService!
    private var mockAnalyticsService: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        mockRateService = MockBitcoinRateService()
        mockAnalyticsService = MockAnalyticsService()
        
        sut = AnalyticsRateObserver(
            rateService: mockRateService,
            analyticsService: mockAnalyticsService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockRateService = nil
        mockAnalyticsService = nil
        super.tearDown()
    }
    
    func testRateUpdate_TriggersCorrectAnalyticsEvent() async {
        // GIVEN
        let testRate = 65432.12345
        
        // WHEN
        mockRateService.ratePublisherSubject.send(testRate)
        try? await Task.sleep(for: .milliseconds(100)) // A small delay to allow the async Task inside the observer to run
        
        // THEN: The analytics service should be called with the correct data
        XCTAssertEqual(mockAnalyticsService.trackEventCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.lastTrackedEventName, "bitcoin_rate_update")
        XCTAssertEqual(mockAnalyticsService.lastTrackedParameters?["rate"], "65432.12")
    }
}

// MARK: - Mocks

final private class MockBitcoinRateService: BitcoinRateService {
    let ratePublisherSubject = PassthroughSubject<Double, Never>()
    var ratePublisher: AnyPublisher<Double, Never> {
        ratePublisherSubject.eraseToAnyPublisher()
    }
    
    func start() {}
    func stop() {}
}

final private class MockAnalyticsService: AnalyticsService {
    var trackEventCallCount = 0
    var lastTrackedEventName: String?
    var lastTrackedParameters: [String: String]?
    
    func trackEvent(name: String, parameters: [String: String], date: Date) async {
        trackEventCallCount += 1
        lastTrackedEventName = name
        lastTrackedParameters = parameters
    }
    
    func events(named name: String?, between startDate: Date, and endDate: Date) async -> [AnalyticsEvent] {
        []
    }
}
