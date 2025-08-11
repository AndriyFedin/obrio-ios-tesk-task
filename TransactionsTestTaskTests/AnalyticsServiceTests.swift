//
//  AnalyticsServiceTests.swift
//  TransactionsTestTaskTests
//
//  Created by Andriy Fedin on 09.08.2025.
//

import XCTest
@testable import TransactionsTestTask

final class AnalyticsServiceTests: XCTestCase {

    var sut: AnalyticsServiceImpl!

    override func setUp() {
        super.setUp()
        sut = AnalyticsServiceImpl()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testTrackEvent_AddsEventCorrectly() async {
        // Given
        let eventName = "test_event"
        let eventParams = ["key": "value"]
        
        // When
        await sut.trackEvent(name: eventName, parameters: eventParams)
        
        // Then
        let allEvents = await sut.events(named: nil, between: .distantPast, and: .distantFuture)
        XCTAssertEqual(allEvents.count, 1)
        XCTAssertEqual(allEvents.first?.name, eventName)
        XCTAssertEqual(allEvents.first?.parameters, eventParams)
    }
    
    func testEventFiltering_ByNameAndDateRange() async {
        // Given
        let now = Date()
        let event1Date = now.addingTimeInterval(-100)
        let event2Date = now
        let event3Date = now.addingTimeInterval(100)
        
        await sut.trackEvent(name: "event_A", parameters: [:], date: event1Date) // Outside date range
        await sut.trackEvent(name: "event_A", parameters: [:], date: event2Date) // Inside date range
        await sut.trackEvent(name: "event_B", parameters: [:], date: event2Date) // Wrong name
        await sut.trackEvent(name: "event_A", parameters: [:], date: event3Date) // Outside date range
        
        let startDate = now.addingTimeInterval(-10)
        let endDate = now.addingTimeInterval(10)
        
        // When
        let filteredEvents = await sut.events(named: "event_A", between: startDate, and: endDate)
        
        // Then
        XCTAssertEqual(filteredEvents.count, 1)
        XCTAssertEqual(filteredEvents.first?.name, "event_A")
        XCTAssertEqual(filteredEvents.first?.date, event2Date)
    }
}
