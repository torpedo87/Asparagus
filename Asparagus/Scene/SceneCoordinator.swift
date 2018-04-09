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
    case .root:
      currentViewController = SceneCoordinator.actualViewController(for: viewController)
      window.rootViewController = viewController
      subject.onCompleted()
      
    case .push:
      var navigationController: UINavigationController
      print(currentViewController)
      if let taskViewController = currentViewController as? TaskViewController {
        if let nav = taskViewController.navigationController {
          if let sideBarViewController = nav.parent as? SidebarViewController {
            sideBarViewController.viewModel.isScroll.onNext(false)
          }
        }
      }
      if let sideBarViewController = currentViewController as? SidebarViewController {
        navigationController = currentViewController.childViewControllers.last as! UINavigationController
        sideBarViewController.viewModel.isScroll.onNext(false)
      } else {
        navigationController = currentViewController.navigationController!
      }
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
      currentViewController.dismiss(animated: animated) {
        self.currentViewController = SceneCoordinator.actualViewController(for: presenter)
        subject.onCompleted()
      }
    } else if let navigationController = currentViewController.navigationController {
      if let editViewController = currentViewController as? EditViewController {
        if let nav = editViewController.navigationController {
          if let sideBarViewController = nav.parent as? SidebarViewController {
            sideBarViewController.viewModel.isScroll.onNext(true)
          }
        }
      }
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

