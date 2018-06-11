//
//  IssueViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct IssueViewModel {
  private let bag = DisposeBag()
  var selectedRepo: LocalRepository
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskService
  private let authService: AuthServiceRepresentable
  private let issueService: IssueServiceRepresentable
  let searchText = BehaviorRelay<String>(value: "")
  
  init(selectedRepo: LocalRepository,
       issueService: IssueServiceRepresentable,
       coordinator: SceneCoordinatorType,
       localTaskService: LocalTaskService,
       authService: AuthServiceRepresentable) {
    self.selectedRepo = selectedRepo
    self.localTaskService = localTaskService
    self.sceneCoordinator = coordinator
    self.authService = authService
    self.issueService = issueService
  }
  
  func onToggle(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  func onStar(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggleStar(task: task).map{ _ in }
    }
  }
  
  var sectionedItems: Observable<[TaskSection]> {
    return self.searchText.asObservable()
      .flatMap({ query in
        return self.localTaskService.tasksForLocalRepo(repoUid: self.selectedRepo.uid, query: query)
      })
      .map { results in
        let dueTasks = results
          .filter("title != '' AND checked = 'open' AND isDeleted == false")
          .sorted(byKeyPath: "added", ascending: false)
        
        let doneTasks = results
          .filter("title != '' AND checked = 'closed' AND isDeleted == false")
          .sorted(byKeyPath: "added", ascending: false)
        
        return [
          TaskSection(header: "Due Tasks", items: dueTasks.toArray()),
          TaskSection(header: "Done Tasks", items: doneTasks.toArray())
        ]
    }
  }
  
  lazy var editAction: Action<TaskItem, Swift.Never> = { this in
    
    return Action { task in
      let editViewModel = IssueDetailViewModel(task: task,
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
        .transition(to: .issueDetail(editViewModel), type: .push)
        .asObservable()
    }
  }(self)
  
  func onDelete(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.deleteTaskOnMain(localTask: task)
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
  
  func onUpdateRepo(task: TaskItem) -> CocoaAction {
    return CocoaAction {
      if let repo = self.localTaskService.getRepository(repoName: self.selectedRepo.name) {
        return self.localTaskService.updateRepo(exTask: task,
                                                repo: repo).map { _ in }
      } else {
        return .empty()
      }
      
    }
  }
  
  func onCreateTask() -> CocoaAction {
    return CocoaAction { _ in
      if self.selectedRepo.uid == "Today" {
        return .empty()
      }
      return self.localTaskService.createBlankTask(title: "")
        .flatMap { task -> Observable<Void> in
          let viewModel = IssueDetailViewModel(task: task,
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
            .transition(to: Scene.issueDetail(viewModel), type: .push)
            .asObservable().map { _ in }
      }
    }
  }
  
  func popView() -> CocoaAction {
    return CocoaAction { _ in
      return self.sceneCoordinator.pop()
        .asObservable().map{ _ in }
    }
  }
}

