//
//  EditViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 2..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RxDataSources

struct EditViewModel {
  
  let task: TaskItem
  let onDelete: Action<TaskItem, Void>
  let onUpdate: Action<(String, String, [String]), Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskServiceType
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       deleteAction: Action<TaskItem, Void>,
       updateAction: Action<(String, String, [String]), Void>,
       localTaskService: LocalTaskServiceType) {
    self.task = task
    self.onDelete = deleteAction
    self.onUpdate = updateAction
    self.localTaskService = localTaskService
    
    onUpdate.executionObservables
      .take(1)
      .subscribe(onNext: { _ in
        coordinator.pop()
      })
      .disposed(by: bag)
    
    onDelete.executionObservables
      .take(1)
      .subscribe(onNext: { _ in
        coordinator.pop()
      })
      .disposed(by: bag)
  }
  
  func findAllTagsFromText(tagText: String) -> [String] {
    let tagsArr = tagText.trimmingCharacters(in: .whitespaces).components(separatedBy: "#").filter{ $0 != "" }
    return tagsArr
  }
  
//  var sectionedItems: Observable<[TotalSection]> {
//    return localTaskService.subTasksForTask(task: task)
//      .map({ results in
//        let dueTasks = results
//          .filter("checked = 'open'")
//          .sorted(byKeyPath: "added", ascending: false)
//
//        let doneTasks = results
//          .filter("checked = 'closed'")
//          .sorted(byKeyPath: "added", ascending: false)
//
//        return [
//          TotalSection(header: "Title", items: [.text("")]),
//          TotalSection(header: "Body", items: [.text("")]),
//          TotalSection(header: "Repository", items: [.text("")]),
//          TotalSection(header: "Tags with #", items: [.text("")]),
//          TotalSection(header: "Due SubTasks", items: dueTasks.toArray().map{ .subTask($0)}),
//          TotalSection(header: "Done SubTasks", items: doneTasks.toArray().map{ .subTask($0)})
//        ]
//      })
//  }
  
  func onToggle(task: SubTask) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  func addSubTask() {
    localTaskService.createSubTask(title: "aaa", superTask: task)
  }
}
