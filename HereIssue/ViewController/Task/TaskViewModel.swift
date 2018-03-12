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
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskServiceType
  private let authService: AuthServiceRepresentable
  private let issueService: IssueServiceRepresentable
  private let syncService: SyncServiceRepresentable
  
  //output
  let isLoggedIn = BehaviorRelay<Bool>(value: false)
  let running = BehaviorRelay<Bool>(value: true)
  
  init(issueService: IssueServiceRepresentable = IssueService(),
       coordinator: SceneCoordinatorType = SceneCoordinator(),
       localTaskService: LocalTaskServiceType = LocalTaskService(),
       authService: AuthServiceRepresentable = AuthService(),
       syncService: SyncServiceRepresentable) {
    self.localTaskService = localTaskService
    self.sceneCoordinator = coordinator
    self.authService = authService
    self.issueService = issueService
    self.syncService = syncService
    
    //로그인상태시 이슈 가져오기
    let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
    authService.isLoggedIn.asObservable()
      .filter { $0 == true }
      .subscribeOn(globalScheduler)
      .subscribe(onNext: { _ in
        syncService.syncStart(fetchedTasks: issueService.fetchAllIssues(page: 1))
      })
      .disposed(by: bag)
    
    //로그인 상태시 내 정보 가져오기
    authService.isLoggedIn.asObservable()
      .filter { $0 == true }
      .flatMap { _ -> Observable<User> in
        return issueService.getUser()
      }.subscribe(onNext: { user in
        UserDefaults.saveMe(me: user)
      })
      .disposed(by: bag)
    
    bindOutput()
  }
  
  func bindOutput() {
    authService.isLoggedIn
      .drive(isLoggedIn)
      .disposed(by: bag)
    
    syncService.running
      .asDriver()
      .drive(running)
      .disposed(by: bag)
  }
  
  func onToggle(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  var sectionedItems: Observable<[TaskSection]> {
    return self.localTaskService.tasks()
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
                                        updateAction: this.onUpdateTask(task: task),
                                        localTaskService: this.localTaskService)
      return this.sceneCoordinator
        .transition(to: Scene.edit(editViewModel), type: .modal)
        .asObservable()
    }
  }(self)
  
  func onUpdateTask(task: TaskItem) -> Action<(String, String), Void> {
    return Action { tuple in
      return self.localTaskService.updateTitleBody(exTask: task, newTitle: tuple.0, newBody: tuple.1).map { _ in }
    }
  }
  
  func onCreateTask() -> Action<(String, String, String), Void> {
    return Action { tuple in
      return self.localTaskService.createTask(title: tuple.0, body: tuple.1, repoName: tuple.2).map { _ in }
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
  
  func goToCreate() -> CocoaAction {
    return CocoaAction { _ in
      let createViewModel = CreateViewModel(coordinator: self.sceneCoordinator,
                                            createAction: self.onCreateTask(),
                                            localTaskService: self.localTaskService)
      return self.sceneCoordinator
        .transition(to: Scene.create(createViewModel), type: .modal)
        .asObservable().map { _ in }
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
