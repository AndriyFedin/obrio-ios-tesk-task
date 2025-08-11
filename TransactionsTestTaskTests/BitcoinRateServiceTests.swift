//
//  BitcoinRateServiceTests.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import XCTest
import Combine
@testable import TransactionsTestTask

final class BitcoinRateServiceTests: XCTestCase {
    
    var sut: BitcoinRateServiceImpl!
    var mockCache: MockRateCache!
    var cancellables: Set<AnyCancellable>!
    let testURL = URL(string: "https://apple.com")!
    var sessionConfiguration: URLSessionConfiguration!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        cancellables = []
        mockCache = MockRateCache()
        
        sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: sessionConfiguration)
        
        sut = BitcoinRateServiceImpl(
            updateInterval: 15,
            session: mockSession,
            cache: mockCache,
            url: testURL
        )
    }
    
    override func tearDown() {
        sut?.stop()
        sut = nil
        mockCache = nil
        cancellables = nil
        MockURLProtocol.mockResponses = [:]
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testFetchRate_Success_PublishesAndCachesRate() async {
        // GIVEN: A successful network response
        let price = 123456.78
        let jsonString = """
        { "symbol": "BTCUSDT", "price": "\(price)" }
        """
        MockURLProtocol.mockResponses[testURL] = .success(Data(jsonString.utf8))
        
        let expectation = XCTestExpectation(description: "Should publish the fetched rate")
        var receivedRate: Double?
        
        sut.ratePublisher
            .sink { rate in
                receivedRate = rate
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // WHEN: We fetch the rate
        sut.start()
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // THEN: The correct rate is published and cached
        XCTAssertEqual(receivedRate, price)
        XCTAssertEqual(mockCache.savedRate, price)
        XCTAssertEqual(mockCache.saveCallCount, 1)
    }

    func testFetchRate_NetworkFailure_PublishesCachedRate() async {
        // GIVEN: A network error and a pre-existing cached rate
        let cachedPrice = 80085.55
        mockCache = MockRateCache(initialRate: cachedPrice)
        sut = BitcoinRateServiceImpl(session: mockSession, cache: mockCache, url: testURL)
        
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        MockURLProtocol.mockResponses[testURL] = .failure(networkError)
        
        let expectation = XCTestExpectation(description: "Should publish the cached rate")
        var receivedRate: Double?
        
        sut.ratePublisher
            .sink { rate in
                receivedRate = rate
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // WHEN: We start the service
        sut.start()
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // THEN: The cached rate is published
        XCTAssertEqual(receivedRate, cachedPrice)
        XCTAssertEqual(mockCache.saveCallCount, 0)
    }
    
    func testFetchRate_ParsingFailure_PublishesCachedRate() async {
        // GIVEN: A malformed JSON response and a cached rate
        let cachedPrice = 1_000_000.01
        mockCache = MockRateCache(initialRate: cachedPrice)
        sut = BitcoinRateServiceImpl(session: mockSession, cache: mockCache, url: testURL)
        
        let jsonString = """
        { "symbol": "BTCUSDT", "price": "not_a_double" }
        """
        MockURLProtocol.mockResponses[testURL] = .success(Data(jsonString.utf8))
        
        let expectation = XCTestExpectation(description: "Should publish the cached rate on parsing failure")
        var receivedRate: Double?
        
        sut.ratePublisher
            .sink { rate in
                receivedRate = rate
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // WHEN: We fetch the rate
        sut.start()
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // THEN: The cached rate is published
        XCTAssertEqual(receivedRate, cachedPrice)
        XCTAssertEqual(mockCache.saveCallCount, 0)
    }
    
    func testFetchRate_TotalFailure_DoesNotPublish() async {
        // GIVEN: A network error and an empty cache
        let networkError = NSError(domain: NSURLErrorDomain, code: 404, userInfo: nil)
        MockURLProtocol.mockResponses[testURL] = .failure(networkError)
        
        var receivedValue = false
        sut.ratePublisher
            .sink { _ in
                receivedValue = true
            }
            .store(in: &cancellables)
        
        // WHEN: We fetch the rate
        sut.start()
        
        // THEN: Nothing is published
        try? await Task.sleep(for: .milliseconds(100)) // A small delay to ensure the publisher had a chance to fire
        XCTAssertFalse(receivedValue, "Publisher should not emit any value on total failure")
    }
}
