//
//  PopUpViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 21..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RxDataSources

struct PopUpViewModel {
  
  let task: TaskItem
  let onUpdateTags: Action<(Tag, LocalTaskService.EditMode), Void>
  let onUpdateAssignees: Action<(Assignee, LocalTaskService.EditMode), Void>
  private let bag = DisposeBag()
  private let localTaskService: LocalTaskServiceType
  private let issueService: IssueServiceRepresentable
  private let coordinator: SceneCoordinatorType
  let repoTitles = BehaviorRelay<[String]>(value: [])
  let selectedRepoTitle = BehaviorRelay<String>(value: "")
  
  init(task: TaskItem,
       coordinator: SceneCoordinatorType,
       updateTagsAction: Action<(Tag, LocalTaskService.EditMode), Void>,
       updateAssigneesAction: Action<(Assignee, LocalTaskService.EditMode), Void>,
       localTaskService: LocalTaskServiceType,
       issueService: IssueServiceRepresentable,
       editViewModel: EditViewModel) {
    self.task = task
    self.onUpdateTags = updateTagsAction
    self.onUpdateAssignees = updateAssigneesAction
    self.localTaskService = localTaskService
    self.coordinator = coordinator
    self.issueService = issueService
    
    localTaskService.repositories()
      .map { results -> [String] in
        let titles = results.map { $0.name }
        let filteredTitles = Array(Set(titles))
        return filteredTitles
      }.asDriver(onErrorJustReturn: [])
      .drive(repoTitles)
      .disposed(by: bag)
    
    selectedRepoTitle.asObservable()
      .bind(to: editViewModel.selectedRepoTitle)
      .disposed(by: bag)
  }
  
  func dismissView() {
    coordinator.pop()
  }
  
  func repoUsers() -> Observable<[User]> {
    if let repo = task.repository {
      return issueService.getRepoUsers(repo: repo)
    } else {
      return Observable<[User]>.just([])
    }
  }
  
  func tags() -> Observable<[Tag]> {
    return localTaskService.tagsForTask(task: task)
      .map({ result -> [Tag] in
        let tags = result.toArray()
        let filteredTags = Array(Set(tags))
        let newTag = Tag()
        var temp = [newTag]
        filteredTags.forEach({ (tag) in
          temp.append(tag)
        })
        return temp
      })
  }
}

