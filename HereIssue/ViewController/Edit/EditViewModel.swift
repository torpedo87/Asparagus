//
//  EditViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 2..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct EditViewModel {
  
  var task: TaskItem
  let onCancel: CocoaAction!
  let onUpdate: Action<(String, String), Void>
  let bag = DisposeBag()
  let localTaskService: LocalTaskServiceType
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       updateAction: Action<(String, String), Void>,
       localTaskService: LocalTaskServiceType) {
    self.task = task
    self.onUpdate = updateAction
    self.localTaskService = localTaskService
    
    onCancel = CocoaAction {
      return coordinator.pop()
        .asObservable().map { _ in }
    }
    
    onUpdate.executionObservables
      .take(1)
      .subscribe(onNext: { _ in
        coordinator.pop()
      })
      .disposed(by: bag)
    
  }
  
}
