//
//  SyncViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct SyncViewModel {
  private let bag = DisposeBag()
  private let sceneCoordinator: SceneCoordinatorType
  private let authService: AuthServiceRepresentable
  
  
  init(authService: AuthServiceRepresentable,
       coordinator: SceneCoordinatorType) {
    self.authService = authService
    self.sceneCoordinator = coordinator
  }
  
  func isLoggedIn() -> Observable<Bool> {
    return authService.loginStatus.asObservable()
  }
  
  func dismissView() -> CocoaAction {
    return CocoaAction {
      return self.sceneCoordinator.pop()
        .asObservable().map{ _ in }
    }
  }
  
  func authVC() -> AuthViewController {
    var vc = AuthViewController()
    vc.bindViewModel(to: self)
    return vc
  }
  
  func onForgotPassword() -> CocoaAction {
    return CocoaAction {
      return Observable.create({ (observer) -> Disposable in
        if let url = URL(string: "https://github.com/password_reset") {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
  }
  
  func onAuthTask() -> Action<(String, String), AuthService.AccountStatus> {
    return Action { tuple in
      if let _ = UserDefaults.loadToken() {
        return self.authService.removeToken(userId: tuple.0, userPassword: tuple.1)
      } else {
        return self.authService.requestToken(userId: tuple.0, userPassword: tuple.1)
      }
    }
  }
}

