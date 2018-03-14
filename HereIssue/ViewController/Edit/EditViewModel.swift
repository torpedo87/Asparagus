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
  
  let task: TaskItem
  let onUpdate: Action<(String, String), Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskServiceType
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       updateAction: Action<(String, String), Void>,
       localTaskService: LocalTaskServiceType) {
    self.task = task
    self.onUpdate = updateAction
    self.localTaskService = localTaskService
    
    onUpdate.executionObservables
      .take(1)
      .subscribe(onNext: { _ in
        coordinator.pop()
      })
      .disposed(by: bag)
    
  }
  
}
