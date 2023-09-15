//
//  AppCoordinator.swift
//  HumanVision
//
//  Created by Emery Hollingsworth on 9/14/23.
//

import Foundation
import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }

    func start() {
        let viewController = ViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: false)
    }
}

extension AppCoordinator: ViewControllerDelegate {
    // functions from protocol
}

