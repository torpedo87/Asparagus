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

struct LeftViewModel {
  private let bag = DisposeBag()
  private let authService: AuthServiceRepresentable
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskServiceType
  let selectedGroupTitle = PublishSubject<String>()
  
  init(authService: AuthServiceRepresentable = AuthService(),
       coordinator: SceneCoordinatorType = SceneCoordinator(),
       localTaskService: LocalTaskServiceType = LocalTaskService()) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.localTaskService = localTaskService
  }
  
  var sectionedItems: Observable<[TagSection]> {
    return localTaskService.tags()
      .map { results in
        let inboxTag = Tag()
        inboxTag.title = "Inbox"
        let inboxItems = [inboxTag]
        let tagItems = results
          .filter("tasks.@count > 0")
          .filter("title != 'Inbox'")
          .sorted(byKeyPath: "title", ascending: true)
          .toArray()
        
        return [
          TagSection(header: "Inbox", items: inboxItems),
          TagSection(header: "Tags", items: tagItems)
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
}
