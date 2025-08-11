//
//  BitcoinServiceMocks.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import Foundation
import XCTest
@testable import TransactionsTestTask

final class MockRateCache: RateCache {
    private(set) var savedRate: Double?
    var saveCallCount = 0
    
    init(initialRate: Double? = nil) {
        self.savedRate = initialRate
    }
    
    func save(rate: Double) {
        savedRate = rate
        saveCallCount += 1
    }
    
    func load() -> Double? {
        return savedRate
    }
}

final class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: Result<Data, Error>] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            XCTFail("Request URL should not be nil.")
            return
        }
        
        guard let mockResponse = MockURLProtocol.mockResponses[url] else {
            XCTFail("No mock response set for URL: \(url)")
            return
        }
        
        switch mockResponse {
        case .success(let data):
            client?.urlProtocol(self, didLoad: data)
            if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
}
