//
//  DetailViewModel.swift
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

struct DetailViewModel {
  
  let task: TaskItem
  let onDelete: Action<TaskItem, Void>
  let onUpdateBodyTitle: Action<(String, String), Void>
  let onUpdateTags: Action<(Tag, LocalTaskService.TagMode), Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskServiceType
  let sceneCoordinator: SceneCoordinatorType
  let repoTitles = BehaviorRelay<[String]>(value: [])
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       deleteAction: Action<TaskItem, Void>,
       updateTitleBodyAction: Action<(String, String), Void>,
       updateTagsAction: Action<(Tag, LocalTaskService.TagMode), Void>,
       localTaskService: LocalTaskServiceType) {
    self.task = task
    self.onDelete = deleteAction
    self.onUpdateBodyTitle = updateTitleBodyAction
    self.onUpdateTags = updateTagsAction
    self.localTaskService = localTaskService
    self.sceneCoordinator = coordinator
    
    onUpdateBodyTitle.executionObservables
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
    
    localTaskService.repositories()
      .map { results -> [String] in
        let titles = results.map { $0.name }
        let filteredTitles = Array(Set(titles))
        return filteredTitles
      }.asDriver(onErrorJustReturn: [])
      .drive(repoTitles)
      .disposed(by: bag)
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
          SubTaskSection(header: "Add newTask", items: [newTask]),
          SubTaskSection(header: "Due SubTasks", items: dueTasks.toArray()),
          SubTaskSection(header: "Done SubTasks", items: doneTasks.toArray())
        ]
      })
  }
  
  func onToggle(task: SubTask) -> CocoaAction {
    return CocoaAction {
      return self.localTaskService.toggle(task: task).map { _ in }
    }
  }
  
  func addSubTask(title: String) {
    localTaskService.createSubTask(title: title, superTask: task)
  }
  
  func repositoryButtonTapped() -> CocoaAction {
    return CocoaAction { _ in
      return self.sceneCoordinator
        .transition(to: Scene.repository(self), type: .push)
        .asObservable().map { _ in }
    }
  }
  
  func tags() -> Observable<[Tag]> {
    return localTaskService.tagsForTask(task: task)
      .map({ result -> [Tag] in
        let tags = result.toArray()
        let newTag = Tag()
        var temp = [newTag]
        tags.forEach({ (tag) in
          temp.append(tag)
        })
        return temp
      })
  }
  
  func pop() {
    sceneCoordinator.pop()
  }
}
