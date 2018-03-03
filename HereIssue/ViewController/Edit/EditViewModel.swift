//
//  EditViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 2..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct EditViewModel {
  
  var task: TaskItem
  let onCancel: CocoaAction!
  let onUpdate: Action<(String, String), Void>
  let bag = DisposeBag()
  
  init(task: TaskItem, coordinator: SceneCoordinatorType,
       updateAction: Action<(String, String), Void>, cancelAction: CocoaAction? = nil) {
    self.task = task
    self.onUpdate = updateAction
    
    onCancel = CocoaAction {
      if let cancelAction = cancelAction {
        cancelAction.execute(())
      }
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
