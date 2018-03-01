//
//  TaskViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import Action

struct TaskViewModel {
  private let bag = DisposeBag()
  let sceneCoordinator: SceneCoordinatorType
  private let fetcher: IssueFetcher
  let account: Driver<AuthService.AccountStatus>
  let taskService: TaskServiceType
  
  // MARK: - Output
  
  init(account: Driver<AuthService.AccountStatus>, issueService: IssueServiceRepresentable,
       coordinator: SceneCoordinatorType, taskService: TaskServiceType) {
    self.taskService = taskService
    self.sceneCoordinator = coordinator
    self.account = account
    fetcher = IssueFetcher(account: account, issueService: issueService, taskService: taskService)
    
    fetcher.issues
      .subscribe(onNext: { tasks in
        taskService.fetchTasks(tasks: tasks)
      })
      .disposed(by: bag)
  }
  
  func onToggle(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.taskService.toggle(task: task).map { _ in }
    }
  }
  
  var tasks: Observable<[TaskItem]> {
    return self.taskService.tasks()
      .map { $0.filter { $0.checked == "open" } }
  }
}
