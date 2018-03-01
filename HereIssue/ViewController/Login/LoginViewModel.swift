//
//  LoginViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct LoginViewModel {
  let sceneCoordinator: SceneCoordinatorType
  let authService: AuthServiceRepresentable
  
  //input
  let idTextInput = BehaviorRelay<String>(value: "")
  let pwdTextInput = BehaviorRelay<String>(value: "")
  
  //output
  let validate: Driver<Bool>
  
  init(authService: AuthServiceRepresentable = AuthService(), coordinator: SceneCoordinatorType) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    
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
  }
  
  //토큰 요청
  func requestLogin(id: String, password: String) -> Observable<AuthService.AccountStatus> {
    return authService.requestToken(userId: id, userPassword: password)
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
  
  lazy var loginAction: Action<(String, String), AuthService.AccountStatus> = { this in
    return Action { tuple in
      return this.requestLogin(id: tuple.0, password: tuple.1)
    }
  }(self)
}
