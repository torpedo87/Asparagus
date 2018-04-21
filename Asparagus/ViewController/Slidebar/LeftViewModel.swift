//
//  LeftViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RealmSwift

struct LeftViewModel {
  private let bag = DisposeBag()
  private let authService: AuthServiceRepresentable
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskServiceType
  let selectedItemSubject = PublishSubject<MyModel>()
  let isLoggedIn = BehaviorRelay<Bool>(value: false)
  
  init(authService: AuthServiceRepresentable = AuthService(),
       coordinator: SceneCoordinatorType = SceneCoordinator(),
       localTaskService: LocalTaskServiceType = LocalTaskService()) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.localTaskService = localTaskService
    
    Observable.combineLatest(Reachability.rx.isOnline,
                             authService.isLoggedIn.asObservable())
      .filter { $0.0 && $0.1 }
      .flatMap { _ -> Observable<User> in
        return authService.getUser()
      }
      .map({ user -> Bool in
        UserDefaults.saveMe(me: user)
        return true
      })
      .bind(to: isLoggedIn)
      .disposed(by: bag)
    
    bindOutput()
  }
  
  func bindOutput() {
    authService.isLoggedIn
      .drive(isLoggedIn)
      .disposed(by: bag)
  }
  
  var sectionedItems: Observable<[TotalSection]> {
    //List 타입을 합칠 방법이 필요하다
    return Observable.combineLatest(localTaskService.tags(), localTaskService.localRepositories())
      .map { (tagResults, localRepoResults) -> [TotalSection] in
        var localRepoItems = [LocalRepository]()
        var tagItems = [Tag]()
        
        localRepoItems = localRepoResults
          .filter("tasks.@count > 0")
          .sorted(byKeyPath: "name", ascending: true)
          .toArray()
        
        tagItems = tagResults
          .filter("tasks.@count > 0")
          .sorted(byKeyPath: "title", ascending: true)
          .toArray()
        
        return [
          TotalSection(header: "Inbox", items: [.inbox("inbox")]),
          TotalSection(header: "Repository", items: localRepoItems.map{ .localRepo($0)}),
          TotalSection(header: "Tag", items: tagItems.map{ .tag($0) })
        ]
    }
  }
  
  func goToSetting() -> CocoaAction {
    return CocoaAction { _ in
      let settingViewModel = SettingViewModel(authService: self.authService,
                                              sceneCoordinator: self.sceneCoordinator)
      let settingScene = Scene.setting(settingViewModel)
      return self.sceneCoordinator.transition(to: settingScene, type: .modal)
        .asObservable().map { _ in }
    }
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
  
  func onAuth() -> CocoaAction {
    return CocoaAction {
      let isLoggedIn = UserDefaults.loadToken() != nil
      let authViewModel = AuthViewModel(authService: self.authService,
                                        coordinator: self.sceneCoordinator,
                                        authAction: self.onAuthTask(isLoggedIn: isLoggedIn))
      let authScene = Scene.auth(authViewModel)
      return self.sceneCoordinator.transition(to: authScene, type: .modal)
        .asObservable()
        .map{ _ in }
    }
  }
}
