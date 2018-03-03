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
  let authService: AuthServiceRepresentable
  
  init(account: Driver<AuthService.AccountStatus>,
       issueService: IssueServiceRepresentable,
       coordinator: SceneCoordinatorType,
       taskService: TaskServiceType,
       authService: AuthServiceRepresentable = AuthService()) {
    self.taskService = taskService
    self.sceneCoordinator = coordinator
    self.account = account
    self.authService = authService
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
  
  var sectionedItems: Observable<[TaskSection]> {
    return self.taskService.tasks()
      .map { results in
        let dueTasks = results
          .filter("checked == 'open'")
          .sorted(byKeyPath: "added", ascending: false)
        
        let doneTasks = results
          .filter("checked == 'closed'")
          .sorted(byKeyPath: "added", ascending: false)
        
        return [
          TaskSection(header: "Due Tasks", items: dueTasks.toArray()),
          TaskSection(header: "Done Tasks", items: doneTasks.toArray())
        ]
    }
  }
  
  lazy var editAction: Action<TaskItem, Swift.Never> = { this in
    return Action { task in
      let editViewModel = EditViewModel(task: task,
                                        coordinator: this.sceneCoordinator,
                                        updateAction: this.onUpdateTask(task: task))
      return this.sceneCoordinator
        .transition(to: Scene.edit(editViewModel), type: .modal)
        .asObservable()
    }
  }(self)
  
  func onUpdateTask(task: TaskItem) -> Action<(String, String), Void> {
    return Action { tuple in
      return self.taskService.update(task: task, title: tuple.0, body: tuple.1).map { _ in }
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
  
  func onDelete(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.taskService.delete(task: task)
    }
  }
  
  func onCreateTask() -> CocoaAction {
    return CocoaAction { _ in
      return self.taskService
        .createTask(title: "")
        .flatMap { task -> Observable<Void> in
          let editViewModel = EditViewModel(task: task,
                                            coordinator: self.sceneCoordinator,
                                            updateAction: self.onUpdateTask(task: task),
                                            cancelAction: self.onDelete(task: task))
          return self.sceneCoordinator
            .transition(to: Scene.edit(editViewModel), type: .modal)
            .asObservable().map { _ in }
      }
    }
  }
  
  func onAuth() -> CocoaAction {
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