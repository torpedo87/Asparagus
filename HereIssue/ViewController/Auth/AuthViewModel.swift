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
  let sceneCoordinator: SceneCoordinatorType
  let authService: AuthServiceRepresentable
  let onAuth: Action<(String, String), AuthService.AccountStatus>
  let onCancel: CocoaAction!
  
  //input
  let idTextInput = BehaviorRelay<String>(value: "")
  let pwdTextInput = BehaviorRelay<String>(value: "")
  
  //output
  let validate: Driver<Bool>
  let loggedIn: Driver<Bool>
  
  init(authService: AuthServiceRepresentable = AuthService(),
       coordinator: SceneCoordinatorType,
       authAction: Action<(String, String), AuthService.AccountStatus>) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.onAuth = authAction
    
    let isIdValid = idTextInput.asObservable()
      .map { (text) -> Bool in
        if text.isEmpty {
          return false
        }
        return true
    }
    
    let isPwdValid = pwdTextInput.asObservable()
      .map { (text) -> Bool in
        if text.isEmpty {
          return false
        }
        return true
    }
    
    //아이디와 비번의 동시 유효성
    validate = Observable.combineLatest(isIdValid, isPwdValid)
      .map{ tuple -> Bool in
        if tuple.0 == true && tuple.1 == true {
          return true
        }
        return false
      }
      .asDriver(onErrorJustReturn: false)
    
    onCancel = CocoaAction {
      return coordinator.pop()
        .asObservable().map { _ in }
    }
    
    loggedIn = authService.isLoggedIn
  }
  
  func goToTaskScene() {
    let issueService = IssueService()
    let taskService = TaskService()
    let taskViewModel = TaskViewModel(account: authService.status, issueService: issueService,
                                      coordinator: sceneCoordinator, taskService: taskService)
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
