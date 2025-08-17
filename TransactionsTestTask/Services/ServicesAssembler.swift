//
//  ServicesAssembler.swift
//  TransactionsTestTask
//
//

// TODO:
/// Services Assembler is used for Dependency Injection
/// There is an example of a _bad_ services relationship built on `onRateUpdate` callback
/// This kind of relationship must be refactored with a more convenient and reliable approach
///
/// It's ok to move the logging to model/viewModel/interactor/etc when you have 1-2 modules in your app
/// Imagine having rate updates in 20-50 diffent modules
/// Make this logic not depending on any module
///

enum ServicesAssembler {
    static var analyticsService: AnalyticsService {
        shared.analyticsService
    }
    
    static var bitcoinRateService: BitcoinRateService {
        shared.bitcoinRateService
    }
    
    static var coreDataService: CoreDataService {
        shared.coreDataService
    }
    
    static var homeViewModel: HomeViewModel {
        shared.homeViewModel
    }
    
    static var addFundsViewModel: AddFundsViewModel {
        shared.addFundsViewModel
    }
    
    static var addTransactionViewModel: AddTransactionViewModel {
        shared.addTransactionViewModel
    }
    
    // MARK: - Private
    
    private static let shared = Container()
    
    private final class Container {
        let analyticsService: AnalyticsService
        let bitcoinRateService: BitcoinRateService
        let coreDataService: CoreDataService
        
        let analyticsRateObserver: AnalyticsRateObserver
        
        let homeViewModel: HomeViewModel
        let addFundsViewModel: AddFundsViewModel
        let addTransactionViewModel: AddTransactionViewModel
        
        init() {
            self.analyticsService = AnalyticsServiceImpl()
            self.bitcoinRateService = BitcoinRateServiceImpl()
            self.coreDataService = CoreDataService()
            
            self.analyticsRateObserver = AnalyticsRateObserver(
                rateService: self.bitcoinRateService,
                analyticsService: self.analyticsService
            )
            
            self.homeViewModel = HomeViewModel(dataSource: coreDataService, rateService: bitcoinRateService)
            self.addFundsViewModel = AddFundsViewModel(transactionCreator: coreDataService)
            self.addTransactionViewModel = AddTransactionViewModel(transactionCreator: coreDataService)
            
            self.bitcoinRateService.start()
        }
    }
}
