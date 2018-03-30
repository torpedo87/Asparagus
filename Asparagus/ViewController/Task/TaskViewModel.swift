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
  let selectedIndex = BehaviorRelay<Int>(value: 0)
  let searchSections = BehaviorRelay<[TaskSection]>(value: [])
  
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
          .filter("title != ''")
          .filter("checked = 'open'")
          .sorted(byKeyPath: "added", ascending: false)

        let doneTasks = results
          .filter("title != ''")
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
      let detailViewModel = DetailViewModel(task: task,
                                        coordinator: this.sceneCoordinator,
                                        deleteAction: this.onDeleteTask(task: task),
                                        updateTitleBodyAction: this.onUpdateTitleBodyTask(task: task),
                                        updateTagsAction: this.onUpdateTagsTask(task: task),
                                        updateRepo: this.onUpdateRepo(task: task),
                                        localTaskService: this.localTaskService)
      return this.sceneCoordinator
        .transition(to: Scene.detail(detailViewModel), type: .push)
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
  
  func onUpdateTitleBodyTask(task: TaskItem) -> Action<(String, String), Void> {
    return Action { tuple in
      return self.localTaskService.updateTitleBody(exTask: task, newTitle: tuple.0, newBody: tuple.1).map { _ in }
    }
  }
  
  func onUpdateTagsTask(task: TaskItem) -> Action<(Tag, LocalTaskService.TagMode), Void> {
    return Action { tuple in
      return self.localTaskService.convertToTaskWithRef(task: task)
        .flatMap { self.localTaskService.updateTag(taskWithRef: $0, tag: tuple.0, mode: tuple.1).map { _ in }}
    }
  }
  
  func onUpdateRepo(task: TaskItem) -> Action<Repository, Void> {
    return Action { repo in
      return self.localTaskService.convertToTaskWithRef(task: task)
        .flatMap { self.localTaskService.updateRepo(taskWithRef: $0, repo: repo).map { _ in }}
    }
  }
  
  func onCreateTask() -> CocoaAction {
    return CocoaAction { _ in
      return self.localTaskService.createBlankTask(title: "")
        .flatMap { task -> Observable<Void> in
          let viewModel = DetailViewModel(task: task,
                                              coordinator: self.sceneCoordinator,
                                              deleteAction: self.onDeleteTask(task: task),
                                              updateTitleBodyAction: self.onUpdateTitleBodyTask(task: task),
                                              updateTagsAction: self.onUpdateTagsTask(task: task),
                                              updateRepo: self.onUpdateRepo(task: task),
                                              localTaskService: self.localTaskService)
          return self.sceneCoordinator
            .transition(to: Scene.detail(viewModel), type: .modal)
            .asObservable().map { _ in }
      }
    }
  }
  
}
