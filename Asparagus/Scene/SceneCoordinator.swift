//
//  SceneCoordinator.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SceneCoordinator: SceneCoordinatorType {
  
  let window: UIWindow = {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.backgroundColor = .white
    window.makeKeyAndVisible()
    return window
  }()
  
  fileprivate var currentViewController: UIViewController!
  lazy var slideInTransitioningDelegate = SlideInPresentationManager()
  
  static func actualViewController(for viewController: UIViewController) -> UIViewController {
    if let navigationController = viewController as? UINavigationController {
      return navigationController.viewControllers.first!
    } else {
      return viewController
    }
  }
  
  @discardableResult
  func transition(to scene: Scene, type: SceneTransitionType) -> Completable {
    let subject = PublishSubject<Void>()
    let viewController = scene.viewController()
    switch type {
    case .popover:
      let nav = UINavigationController(rootViewController: viewController)
      nav.modalPresentationStyle = .popover
      nav.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 100,
                                        height: UIScreen.main.bounds.height - 200)
      if let popover = nav.popoverPresentationController {
        popover.sourceView = currentViewController.view
        popover.sourceRect = currentViewController.view.frame
        popover.canOverlapSourceViewRect = true
        popover.delegate = viewController as! UIPopoverPresentationControllerDelegate
        popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
      }
      currentViewController.present(nav, animated: false) {
        subject.onCompleted()
      }
      currentViewController = SceneCoordinator.actualViewController(for: nav)
      
    case .slide:
      slideInTransitioningDelegate.direction = .bottom
      viewController.transitioningDelegate = slideInTransitioningDelegate
      viewController.modalPresentationStyle = .custom
      currentViewController.present(viewController, animated: true) {
        subject.onCompleted()
      }
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
      
    case .root:
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
      window.rootViewController = viewController
      subject.onCompleted()
      
    case .push:
      guard let navigationController = currentViewController.navigationController else {
        fatalError("Can't push a view controller without a current navigation controller")
      }
      // one-off subscription to be notified when push complete
      _ = navigationController.rx.delegate
        .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
        .map { _ in }
        .bind(to: subject)
      navigationController.pushViewController(viewController, animated: true)
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
      
    case .modal:
      currentViewController.present(viewController, animated: true) {
        subject.onCompleted()
      }
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
    }
    return subject.asObservable()
      .take(1)
      .ignoreElements()
  }
  
  @discardableResult
  func pop(animated: Bool) -> Completable {
    let subject = PublishSubject<Void>()
    if let presenter = currentViewController.presentingViewController {
      // dismiss a modal controller
      currentViewController.dismiss(animated: animated) {
        self.currentViewController = SceneCoordinator.actualViewController(for: presenter)
        subject.onCompleted()
      }
    } else if let navigationController = currentViewController.navigationController {
      // navigate up the stack
      // one-off subscription to be notified when pop complete
      _ = navigationController.rx.delegate
        .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
        .map { _ in }
        .bind(to: subject)
      guard navigationController.popViewController(animated: animated) != nil else {
        fatalError("can't navigate back from \(currentViewController)")
      }
      currentViewController = SceneCoordinator.actualViewController(for: navigationController.viewControllers.last!)
    } else {
      fatalError("Not a modal, no navigation controller: can't navigate back from \(currentViewController)")
    }
    return subject.asObservable()
      .take(1)
      .ignoreElements()
  }
}
