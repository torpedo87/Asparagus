//
//  IssueDetailViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct IssueDetailViewModel {
  let task: TaskItem
  let onCancel: CocoaAction!
  let onUpdateTitleBody: Action<(String, String), Void>
  let onUpdateTags: Action<(Tag, LocalTaskService.EditMode), Void>
  let onUpdateAssignees: Action<(Assignee, LocalTaskService.EditMode), Void>
  let onAddSubTask: Action<String, Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskService
  private let issueService: IssueServiceRepresentable
  private let authService: AuthServiceRepresentable
  private let coordinator: SceneCoordinatorType
  let slideInTransitioningDelegate = SlideInPresentationManager()
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       cancelAction: CocoaAction? = nil,
       updateTitleBodyAction: Action<(String, String), Void>,
       updateTagsAction: Action<(Tag, LocalTaskService.EditMode), Void>,
       updateAssigneesAction: Action<(Assignee, LocalTaskService.EditMode), Void>,
       updateRepo: CocoaAction,
       addSubTask: Action<String, Void>,
       localTaskService: LocalTaskService,
       issueService: IssueServiceRepresentable,
       authService: AuthServiceRepresentable) {
    self.task = task
    self.onUpdateTitleBody = updateTitleBodyAction
    self.onUpdateTags = updateTagsAction
    self.onUpdateAssignees = updateAssigneesAction
    self.onAddSubTask = addSubTask
    self.localTaskService = localTaskService
    self.coordinator = coordinator
    self.issueService = issueService
    self.authService = authService
    
    onCancel = CocoaAction {
      if let cancelAction = cancelAction {
        if task.title == "" && !task.isServerGeneratedType {
          cancelAction.execute(())
        } else if task.title != "" && !task.isServerGeneratedType {
          updateRepo.execute(())
        }
      }
      return coordinator.pop()
        .asObservable().map { _ in }
    }
  }
  
  var sectionedItems: Observable<[SubTaskSection]> {
    return localTaskService.subTasksForTask(task: task)
      .map({ results in
        let dueTasks = results
          .filter("checked = 'open'")
          .sorted(byKeyPath: "added", ascending: false)
        
        let doneTasks = results
          .filter("checked = 'closed'")
          .sorted(byKeyPath: "added", ascending: false)
        
        let newTask = SubTask()
        return [
          SubTaskSection(header: "Add SubTask", items: [newTask]),
          SubTaskSection(header: "Due SubTasks", items: dueTasks.toArray()),
          SubTaskSection(header: "Done SubTasks", items: doneTasks.toArray())
        ]
      })
  }
  
  func popView() -> CocoaAction {
    return CocoaAction { _ in
      return self.coordinator.pop()
        .asObservable().map{ _ in }
    }
  }
  
  func popup(mode: PopupViewController.PopupMode) -> CocoaAction {
    return CocoaAction { _ in
      return self.coordinator.transition(to: .popup(self, mode), type: .popover)
        .asObservable().map{ _ in }
    }
  }
  
  func slide(mode: PopupViewController.PopupMode) -> CocoaAction {
    return CocoaAction { _ in
      return self.coordinator.transition(to: .popup(self, mode), type: .slide)
        .asObservable().map{ _ in }
    }
  }
  
  func onToggle(task: SubTask) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  func isLoggedIn() -> Observable<Bool> {
    return authService.loginStatus.asObservable()
  }
  
  func repoUsers() -> Observable<[User]> {
    if let repo = task.repository {
      return issueService.getRepoUsers(repo: repo)
    } else {
      return Observable<[User]>.just([])
    }
  }
  
  func tags() -> [Tag] {
    return localTaskService.tagsForTask(task: task)
  }
}
