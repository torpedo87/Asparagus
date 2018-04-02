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
  let onUpdateTags: Action<(Tag, LocalTaskService.TagMode), Void>
  let onAddSubTask: Action<String, Void>
  let onUpdateRepo: Action<Repository?, Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskServiceType
  private let coordinator: SceneCoordinatorType
  let repoTitles = BehaviorRelay<[String]>(value: [])
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       cancelAction: CocoaAction? = nil,
       updateTitleBodyAction: Action<(String, String), Void>,
       updateTagsAction: Action<(Tag, LocalTaskService.TagMode), Void>,
       updateRepo: Action<Repository?, Void>,
       addSubTask: Action<String, Void>,
       localTaskService: LocalTaskServiceType) {
    self.task = task
    self.onUpdateTitleBody = updateTitleBodyAction
    self.onUpdateTags = updateTagsAction
    self.onUpdateRepo = updateRepo
    self.onAddSubTask = addSubTask
    self.localTaskService = localTaskService
    self.coordinator = coordinator
    
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
        .asObservable()
        .map{ _ in }
    }
    
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
  
  func pop() {
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
}
