//
//  MainRouter.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 12.08.2025.
//

import Foundation
import UIKit

final class MainRouter: NSObject {
    
    func routeToInitialViewController(on window: UIWindow) {
        let viewModel = ServicesAssembler.homeViewModel
        viewModel.setRouter(self)
        let viewController = HomeViewController(
            viewModel: viewModel
        )
        navigationController = UINavigationController(rootViewController: viewController)
        window.rootViewController = navigationController
        self.window = window
        
        window.makeKeyAndVisible()
    }
    
    func showAddFunds(from sender: UIView) {
        let addFundsViewController = AddFundsViewController(viewModel: ServicesAssembler.addFundsViewModel)
        addFundsViewController.preferredContentSize = .init(width: 240, height: 80)
        addFundsViewController.modalPresentationStyle = .popover
        
        let addFundsPresentationController = addFundsViewController.popoverPresentationController
        addFundsPresentationController?.permittedArrowDirections = .up
        addFundsPresentationController?.sourceRect = sender.bounds
        addFundsPresentationController?.sourceView = sender
        addFundsPresentationController?.delegate = self
        
        navigationController?.present(addFundsViewController, animated: true, completion: nil)
    }
    
    func showAddTransaction() {
        let addTransactionViewController = AddTransactionViewController(viewModel: ServicesAssembler.addTransactionViewModel)
        let newNavigationController = UINavigationController.init(rootViewController: addTransactionViewController)
        navigationController?.present(newNavigationController, animated: true)
    }
    
    // MARK: - Private
    
    private var window: UIWindow?
    private var navigationController: UINavigationController?
}

// MARK: - UIPopoverPresentationControllerDelegate

extension MainRouter: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none // Make sure it always looks like a pupup
    }
}
