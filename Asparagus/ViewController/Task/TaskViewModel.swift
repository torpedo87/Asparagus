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
  private let localTaskService: LocalTaskService
  private let authService: AuthServiceRepresentable
  private let issueService: IssueServiceRepresentable
  private let syncService: SyncServiceRepresentable
  let selectedItemSubject = BehaviorSubject<MyModel>(value: .inbox("Inbox"))
  let searchSections = BehaviorSubject<[TaskSection]>(value: [])
  
  //output
  let running = BehaviorSubject<Bool>(value: false)
  let menuTap = PublishSubject<Void>()
  
  init(issueService: IssueServiceRepresentable,
       coordinator: SceneCoordinatorType,
       localTaskService: LocalTaskService,
       authService: AuthServiceRepresentable,
       syncService: SyncServiceRepresentable) {
    self.localTaskService = localTaskService
    self.sceneCoordinator = coordinator
    self.authService = authService
    self.issueService = issueService
    self.syncService = syncService
    
    //온라인 및 로그인상태시 이슈 가져오기
    let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
    Observable.combineLatest(Reachability.rx.isOnline,
                             authService.isLoggedIn.asObservable())
      .filter { $0.0 && $0.1 }
      .subscribeOn(globalScheduler)
      .subscribe(onNext: { _ in
        syncService.syncStart(fetchedTasks: issueService.fetchAllIssues(page: 1))
      })
      .disposed(by: bag)
    
    //iconbadgenumber
    if let me = UserDefaults.loadUser() {
      localTaskService.openTasksForAssignee(username: me.name)
        .map { results -> Int in
          return results.count
        }.asDriver(onErrorJustReturn: 0)
        .drive(onNext: { counts in
          UIApplication.shared.applicationIconBadgeNumber = counts
        })
        .disposed(by: bag)
    }
    bindOutput()
  }
  
  func bindOutput() {
    
    let syncRunning = syncService.running.share()
   
    syncRunning
      .bind(to: running)
      .disposed(by: bag)
    
    syncRunning.asObservable()
      .observeOn(MainScheduler.instance)
      .filter{ return !$0 }
      .subscribe(onNext: { _ in
        self.syncService.realTimeSync()
      })
      .disposed(by: bag)
  }
  
  func onToggle(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  var sectionedItems: Observable<[TaskSection]> {
    return selectedItemSubject
      .flatMap({ myModel -> Observable<Results<TaskItem>> in
        switch myModel {
        case .inbox(let inbox):
          if inbox == "Inbox" {
            if let me = UserDefaults.loadUser() {
              return self.localTaskService.tasksForAssignee(username: me.name)
            }
            return .empty()
          } else {
            return self.localTaskService.localTasks()
          }
          
        case .localRepo(let localRepo):
          return self.localTaskService.tasksForLocalRepo(repoUid: localRepo.uid)
          
        case .tag(let tag):
          return self.localTaskService.tasksForTag(tagTitle: tag.title)
        }
      })
      .map { results in
        let dueTasks = results
          .filter("title != '' AND checked = 'open'")
          .sorted(byKeyPath: "added", ascending: false)

        let doneTasks = results
          .filter("title != '' AND checked = 'closed'")
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
                                        updateTitleBodyAction: this.onUpdateTitleBodyTask(task: task),
                                        updateTagsAction: this.onUpdateTags(task: task),
                                        updateAssigneesAction: this.onUpdateAssignees(task: task),
                                        updateRepo: this.onUpdateRepo(task: task),
                                        addSubTask: this.onAddSubTask(task: task),
                                        localTaskService: this.localTaskService,
                                        issueService: this.issueService,
                                        authService: this.authService)
      return this.sceneCoordinator
        .transition(to: Scene.edit(editViewModel), type: .modal)
        .asObservable()
    }
  }(self)
  
  func onDelete(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.deleteTaskOnMain(localTask: task)
        .debug("-------delete--------")
    }
  }
  
  func onUpdateTitleBodyTask(task: TaskItem) -> Action<(String, String), Void> {
    return Action { tuple in
      return self.localTaskService.updateTitleBody(exTask: task,
                                                   newTitle: tuple.0,
                                                   newBody: tuple.1).map { _ in }
    }
  }
  
  func onAddSubTask(task: TaskItem) -> Action<String, Void> {
    return Action { title in
      return self.localTaskService.createSubTask(title: title,
                                                 superTask: task).map{ _ in }
    }
  }
  
  func onUpdateTags(task: TaskItem) -> Action<(Tag, LocalTaskService.EditMode), Void> {
    return Action { tuple in
      return self.localTaskService.updateTag(exTask: task,
                                             tag: tuple.0,
                                             mode: tuple.1).map { _ in }
    }
  }
  
  func onUpdateAssignees(task: TaskItem) -> Action<(Assignee, LocalTaskService.EditMode), Void> {
    return Action { tuple in
      return self.localTaskService.updateAssignee(exTask: task,
                                                  assignee: tuple.0,
                                                  mode: tuple.1).map { _ in }
    }
  }
  
  func onUpdateRepo(task: TaskItem) -> Action<Repository?, Void> {
    return Action { repo in
      return self.localTaskService.updateRepo(exTask: task,
                                              repo: repo).map { _ in }
    }
  }
  
  func onCreateTask() -> CocoaAction {
    return CocoaAction { _ in
      return self.localTaskService.createBlankTask(title: "")
        .flatMap { task -> Observable<Void> in
          let viewModel = EditViewModel(task: task,
                                              coordinator: self.sceneCoordinator,
                                              cancelAction: self.onDelete(task: task),
                                              updateTitleBodyAction: self.onUpdateTitleBodyTask(task: task),
                                              updateTagsAction: self.onUpdateTags(task: task),
                                              updateAssigneesAction: self.onUpdateAssignees(task: task),
                                              updateRepo: self.onUpdateRepo(task: task),
                                              addSubTask: self.onAddSubTask(task: task),
                                              localTaskService: self.localTaskService,
                                              issueService: self.issueService,
                                              authService: self.authService)
          return self.sceneCoordinator
            .transition(to: Scene.edit(viewModel), type: .modal)
            .asObservable().map { _ in }
      }
    }
  }
  
}
