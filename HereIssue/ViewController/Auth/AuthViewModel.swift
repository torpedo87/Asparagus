//
//  AuthViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct AuthViewModel {
  private let bag = DisposeBag()
  private let sceneCoordinator: SceneCoordinatorType
  private let authService: AuthServiceRepresentable
  
  let onAuth: Action<(String, String), AuthService.AccountStatus>
  let onCancel: CocoaAction!
  
  //output
  let loggedIn = BehaviorRelay<Bool>(value: false)
  
  init(authService: AuthServiceRepresentable = AuthService(),
       coordinator: SceneCoordinatorType = SceneCoordinator(),
       authAction: Action<(String, String), AuthService.AccountStatus>) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.onAuth = authAction
    
    onCancel = CocoaAction {
      return coordinator.pop()
        .asObservable().map { _ in }
    }
    
    bindOutput()
  }
  
  private func bindOutput() {
    authService.isLoggedIn
      .drive(loggedIn)
      .disposed(by: bag)
  }
  
  func goToTaskScene() {
    let issueService = IssueService()
    let localTaskService = LocalTaskService()
    let syncService = SyncService(issueService: issueService, localTaskService: localTaskService)
    let taskViewModel = TaskViewModel(issueService: issueService,
                                      coordinator: sceneCoordinator,
                                      localTaskService: localTaskService,
                                      syncService: syncService)
    let taskScene = Scene.task(taskViewModel)
    sceneCoordinator.transition(to: taskScene, type: .root)
  }
  
  func checkReachability() -> Observable<Bool> {
    return Reachability.rx.status
      .map { $0 == .online }
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
}
