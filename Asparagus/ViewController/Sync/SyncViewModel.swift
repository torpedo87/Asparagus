//
//  SyncViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct SyncViewModel {
  private let bag = DisposeBag()
  private let sceneCoordinator: SceneCoordinatorType
  private let authService: AuthServiceRepresentable
  let onAuth: Action<(String, String), AuthService.AccountStatus>
  
  
  init(authService: AuthServiceRepresentable,
       coordinator: SceneCoordinatorType,
       authAction: Action<(String, String), AuthService.AccountStatus>) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.onAuth = authAction
    
    bindOutput()
  }
  
  private func bindOutput() {
    
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
    let authViewModel = AuthViewModel(authService: self.authService,
                                      coordinator: self.sceneCoordinator,
                                      authAction: self.onAuth)
    vc.bindViewModel(to: authViewModel)
    return vc
  }
}

