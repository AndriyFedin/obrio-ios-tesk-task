//
//  SceneDelegate.swift
//  TransactionsTestTask
//
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    let router: MainRouter = .init()
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        router.routeToInitialViewController(on: UIWindow(windowScene: windowScene))
    }
}
