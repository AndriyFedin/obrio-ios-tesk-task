//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

import Foundation
import Combine

protocol BitcoinRateService: AnyObject {
    
    var ratePublisher: AnyPublisher<Double, Never> { get }
    
    func start()
    func stop()
}

final class BitcoinRateServiceImpl {

    var ratePublisher: AnyPublisher<Double, Never> {
        rateUpdateSubject.eraseToAnyPublisher()
    }
    
    init(
        updateInterval: TimeInterval = 15.0, // Default to 15 seconds // TODO: change to minutes
        session: URLSession = .shared,
        cache: RateCache = UserDefaultsRateCache(),
        url: URL = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT")!
    ) {
        self.updateInterval = updateInterval
        self.session = session
        self.cache = cache
        self.url = url
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Private
    
    private let rateUpdateSubject = PassthroughSubject<Double, Never>()
    
    private let updateInterval: TimeInterval
    private let session: URLSession
    private let cache: RateCache
    private let url: URL
    
    private var updateTask: Task<Void, Never>?
    
    private func runUpdateLoop() async {
        while !Task.isCancelled {
            await fetchRate()
            
            try? await Task.sleep(for: .seconds(updateInterval))
        }
    }
    
    private func fetchRate() async {
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(TickerResponse.self, from: data)
            
            guard let price = Double(response.price) else {
                throw RateServiceError.invalidPriceString(response.price)
            }
            
            print("BitcoinRateService: Fetched new rate: \(price)")
            
            rateUpdateSubject.send(price)
            cache.save(rate: price)
        } catch {
            print("BitcoinRateService: Fetch failed: \(error.localizedDescription). Attempting to load from cache.")
            if let cachedRate = cache.load() {
                print("BitcoinRateService: Loaded cached rate: \(cachedRate)")
                rateUpdateSubject.send(cachedRate)
            }
        }
    }
}

// MARK: - BitcoinRateService

extension BitcoinRateServiceImpl: BitcoinRateService {
    
    func start() {
        guard updateTask == nil else { return }
        
        print("BitcoinRateService: Starting updates.")
        updateTask = Task {
            await runUpdateLoop()
        }
    }
    
    func stop() {
        print("BitcoinRateService: Stopping updates.")
        updateTask?.cancel()
        updateTask = nil
    }
}

enum RateServiceError: Error, LocalizedError {
    case invalidPriceString(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPriceString(let price):
            return "Failed to convert the price string \"\(price)\" to a Double."
        }
    }
}
