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
  let account: Driver<AuthService.AccountStatus>
  
  init(coordinator: SceneCoordinatorType, account: Driver<AuthService.AccountStatus>) {
    self.sceneCoordinator = coordinator
    self.account = account
  }
  
  func goToTaskScene() {
    let issueService = IssueService()
    let taskService = TaskService()
    let taskViewModel = TaskViewModel(account: account, issueService: issueService,
                                      coordinator: sceneCoordinator, taskService: taskService)
    let taskScene = Scene.task(taskViewModel)
    sceneCoordinator.transition(to: taskScene, type: .root)
  }
  
  func goToLoginScene() {
    let authService = AuthService()
    let loginViewModel = LoginViewModel(authService: authService, coordinator: sceneCoordinator)
    let loginScene = Scene.login(loginViewModel)
    sceneCoordinator.transition(to: loginScene, type: .root)
  }
}
