//
//  SceneDelegate.swift
//  OkPeriods
//
//  Created by Anu on 03/06/26.
//

import UIKit
import FirebaseAuth
import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var authListener: AuthStateDidChangeListenerHandle?
    private let authenticationManager = AuthenticationManager.shared
    private let navigationController = UINavigationController()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()

        showScreen(for: Auth.auth().currentUser, animated: false)

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.showScreen(for: user, animated: true)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
        authListener = nil
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let incomingURL = URLContexts.first?.url else { return }

        if Auth.auth().canHandle(incomingURL) {
            return
        }

        if GIDSignIn.sharedInstance.handle(incomingURL) {
            return
        }

        _ = authenticationManager.handleIncomingEmailLink(incomingURL)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return
        }

        _ = authenticationManager.handleIncomingEmailLink(incomingURL)
    }

    private func showScreen(for user: User?, animated: Bool) {
        let nextViewController: UIViewController
        if let user {
            nextViewController = HomeViewController(user: user)
        } else {
            nextViewController = AuthenticationViewController()
        }

        let applyScreenChange = {
            self.navigationController.setViewControllers([nextViewController], animated: false)
        }

        guard animated, window != nil else {
            applyScreenChange()
            return
        }

        UIView.transition(
            with: navigationController.view,
            duration: 0.35,
            options: [.transitionCrossDissolve, .allowAnimatedContent],
            animations: applyScreenChange
        )
    }
}
