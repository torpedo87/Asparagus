//
//  EditViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 24..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RxDataSources

struct EditViewModel {
  
  let task: TaskItem
  let onCancel: CocoaAction!
  let onUpdateTitleBody: Action<(String, String), Void>
  let onUpdateTags: Action<(Tag, LocalTaskService.EditMode), Void>
  let onUpdateAssignees: Action<(Assignee, LocalTaskService.EditMode), Void>
  let onAddSubTask: Action<String, Void>
  let onUpdateRepo: Action<Repository?, Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskService
  private let issueService: IssueServiceRepresentable
  private let authService: AuthServiceRepresentable
  private let coordinator: SceneCoordinatorType
  let selectedRepoTitle = BehaviorRelay<String>(value: "")
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       cancelAction: CocoaAction? = nil,
       updateTitleBodyAction: Action<(String, String), Void>,
       updateTagsAction: Action<(Tag, LocalTaskService.EditMode), Void>,
       updateAssigneesAction: Action<(Assignee, LocalTaskService.EditMode), Void>,
       updateRepo: Action<Repository?, Void>,
       addSubTask: Action<String, Void>,
       localTaskService: LocalTaskService,
       issueService: IssueServiceRepresentable,
       authService: AuthServiceRepresentable) {
    self.task = task
    self.onUpdateTitleBody = updateTitleBodyAction
    self.onUpdateTags = updateTagsAction
    self.onUpdateAssignees = updateAssigneesAction
    self.onUpdateRepo = updateRepo
    self.onAddSubTask = addSubTask
    self.localTaskService = localTaskService
    self.coordinator = coordinator
    self.issueService = issueService
    self.authService = authService
    
    onUpdateRepo.executionObservables
      .take(1)
      .subscribe(onNext: { _ in
        coordinator.pop()
      })
      .disposed(by: bag)
    
    onCancel = CocoaAction {
      if let cancelAction = cancelAction {
        cancelAction.execute(())
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
  
  func dismissView() {
    coordinator.pop()
  }
  
  func onToggle(task: SubTask) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  func getRepo(repoName: String) -> Repository? {
    return localTaskService.getRepository(repoName: repoName)
  }
  
  func goToPopUpScene() -> CocoaAction {
    return CocoaAction {
      let viewModel = PopUpViewModel(task: self.task,
                                     coordinator: self.coordinator,
                                     updateTagsAction: self.onUpdateTags,
                                     updateAssigneesAction: self.onUpdateAssignees,
                                     localTaskService: self.localTaskService,
                                     issueService: self.issueService,
                                     authService: self.authService,
                                     editViewModel: self)
      let popUpScene = Scene.popUp(viewModel)
      return self.coordinator.transition(to: popUpScene, type: .modal)
        .asObservable()
        .map{ _ in }
    }
  }
}
