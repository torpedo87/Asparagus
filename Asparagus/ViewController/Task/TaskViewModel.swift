//
//  TaskViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RealmSwift

struct TaskViewModel {
  private let bag = DisposeBag()
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskServiceType
  private let authService: AuthServiceRepresentable
  private let issueService: IssueServiceRepresentable
  private let syncService: SyncServiceRepresentable
  let selectedGroupTitle = BehaviorRelay<String>(value: "Inbox")
  let searchSections = BehaviorRelay<[TaskSection]>(value: [])
  let recentQuerySubject = ReplaySubject<String>.create(bufferSize: 5)
  
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
    Observable.combineLatest(checkReachability().asObservable(),
                             authService.isLoggedIn.asObservable())
      .filter { $0.0 && $0.1 }
      .subscribeOn(globalScheduler)
      .subscribe(onNext: { _ in
        syncService.syncStart(fetchedTasks: issueService.fetchAllIssues(page: 1))
      })
      .disposed(by: bag)
    
    //로그인 상태시 내 정보 가져오기
    Observable.combineLatest(checkReachability().asObservable(),
                             authService.isLoggedIn.asObservable())
      .filter { $0.0 && $0.1 }
      .flatMap { _ -> Observable<User> in
        return issueService.getUser()
      }.subscribe(onNext: { user in
        UserDefaults.saveMe(me: user)
      })
      .disposed(by: bag)
    
    bindOutput()
  }
  
  func bindOutput() {
   
    syncService.running
      .asDriver()
      .drive(running)
      .disposed(by: bag)
  }
  func checkReachability() -> Observable<Bool> {
    return Reachability.rx.status
      .map { $0 == .online }
  }
  
  func onToggle(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  var sectionedItems: Observable<[TaskSection]> {
    return selectedGroupTitle
      .flatMap({ title -> Observable<Results<TaskItem>> in
        if title == "Inbox" {
          return self.localTaskService.openTasks()
        } else {
          return self.localTaskService.tasksForTag(tagTitle: title)
        }
      })
      .map { results in
        let dueTasks = results
          .filter("checked = 'open'")
          .sorted(byKeyPath: "added", ascending: false)
        
        let doneTasks = results
          .filter("checked = 'closed'")
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
                                        deleteAction: this.onDeleteTask(task: task),
                                        updateAction: this.onUpdateTask(task: task),
                                        localTaskService: this.localTaskService)
      return this.sceneCoordinator
        .transition(to: Scene.edit(editViewModel), type: .push)
        .asObservable()
    }
  }(self)
  
  func onDeleteTask(task: TaskItem) -> Action<TaskItem, Void> {
    return Action { task in
      return self.localTaskService.convertToTaskWithRef(task: task)
        .flatMap({ taskWithRef in
          return self.localTaskService.deleteTask(newTaskWithRef: taskWithRef)
        })
        .map { _ in }
    }
  }
  
  func onUpdateTask(task: TaskItem) -> Action<(String, String, [String]), Void> {
    return Action { tuple in
      return self.localTaskService.updateTitleBody(exTask: task, newTitle: tuple.0, newBody: tuple.1, newTags: tuple.2).map { _ in }
    }
  }
  
  func onCreateTask() -> Action<(String, String, String, [String]), Void> {
    return Action { tuple in
      return self.localTaskService.createTask(title: tuple.0, body: tuple.1, repoName: tuple.2, tags: tuple.3).map { _ in }
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
