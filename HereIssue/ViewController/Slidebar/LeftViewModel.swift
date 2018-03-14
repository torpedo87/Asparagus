//
//  LeftViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct LeftViewModel {
  private let bag = DisposeBag()
  private let authService: AuthServiceRepresentable
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskServiceType
  let isLoggedIn = BehaviorRelay<Bool>(value: false)
  let repoList = BehaviorRelay<[String]>(value: [])
  let selectedRepo = BehaviorRelay<String>(value: "")
  
  init(authService: AuthServiceRepresentable = AuthService(),
       coordinator: SceneCoordinatorType = SceneCoordinator(),
       localTaskService: LocalTaskServiceType = LocalTaskService()) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.localTaskService = localTaskService
    bindOutput()
  }
  
  func bindOutput() {
    authService.isLoggedIn
      .drive(isLoggedIn)
      .disposed(by: bag)
    
    localTaskService.repositories()
      .map { results -> [String] in
        let titles = results.map { $0.name }
        let filteredTitles = Array(Set(titles))
        return filteredTitles
      }.asDriver(onErrorJustReturn: [])
      .drive(repoList)
      .disposed(by: bag)
    
    selectedRepo.accept("Inbox")
  }
  
  func onAuthTask(isLoggedIn: Bool) -> Action<(String, String), AuthService.AccountStatus> {
    return Action { tuple in
      if isLoggedIn {
        return self.authService.removeToken(userId: tuple.0, userPassword: tuple.1)
      } else {
        return self.authService.requestToken(userId: tuple.0, userPassword: tuple.1)
      }
    }
  }
  
  func goToAuth() -> CocoaAction {
    return CocoaAction { _ in
      let authService = AuthService()
      let isLoggedIn = UserDefaults.loadToken() != nil
      let authViewModel = AuthViewModel(authService: authService,
                                        coordinator: self.sceneCoordinator,
                                        authAction: self.onAuthTask(isLoggedIn: isLoggedIn))
      let authScene = Scene.auth(authViewModel)
      return self.sceneCoordinator.transition(to: authScene, type: .modal)
        .asObservable().map { _ in }
    }
  }
}
