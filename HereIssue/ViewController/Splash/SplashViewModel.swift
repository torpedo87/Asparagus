//
//  SplashViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct SplashViewModel {
  let sceneCoordinator: SceneCoordinatorType
  let account: Driver<AuthAPI.AccountStatus>
  
  init(coordinator: SceneCoordinatorType, account: Driver<AuthAPI.AccountStatus>) {
    self.sceneCoordinator = coordinator
    self.account = account
  }
  
  func goToTaskScene() {
    let taskViewModel = TaskViewModel(coordinator: sceneCoordinator)
    let taskScene = Scene.task(taskViewModel)
    sceneCoordinator.transition(to: taskScene, type: .root)
  }
  
  func goToLoginScene() {
    let authAPI = AuthAPI()
    let loginViewModel = LoginViewModel(authAPI: authAPI, coordinator: sceneCoordinator)
    let loginScene = Scene.login(loginViewModel)
    sceneCoordinator.transition(to: loginScene, type: .root)
  }
}
