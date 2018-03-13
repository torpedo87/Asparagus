//
//  TaskViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
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
  let selectedRepo = BehaviorRelay<String>(value: "local")
  let tasksForSelectedRepo = BehaviorRelay<[TaskItem]>(value: [])
  
  //output
  let running = BehaviorRelay<Bool>(value: true)
  let menuTap = BehaviorRelay<Void>(value: ())
  
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
    
    selectedRepo.asObservable()
      .flatMap { (name) -> Observable<[TaskItem]> in
        return localTaskService.tasksForRepo(repoName: name)
      }.bind(to: tasksForSelectedRepo)
      .disposed(by: bag)
    
    bindOutput()
  }
  
  func bindOutput() {
   
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
    return self.tasksForSelectedRepo
      .map { results in
        let dueTasks = results
          .filter{ $0.checked == "open" }
        
        let doneTasks = results
          .filter { $0.checked == "closed" }
        
        return [
          TaskSection(header: "Due Tasks", items: dueTasks),
          TaskSection(header: "Done Tasks", items: doneTasks)
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
  
  
}
