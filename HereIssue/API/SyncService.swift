//
//  SyncService.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


protocol SyncServiceRepresentable {
//  func syncWhenTaskEdittedInLocal()
//  func syncWhenTaskCreatedInLocal()
}

class SyncService: SyncServiceRepresentable {
  private let bag = DisposeBag()
  private let issueService: IssueServiceRepresentable
  private let localTaskService: LocalTaskServiceType
  
  init(issueService: IssueServiceRepresentable, localTaskService: LocalTaskServiceType) {
    self.issueService = issueService
    self.localTaskService = localTaskService
    
//    syncWhenTaskEdittedInLocal()
//    syncWhenTaskCreatedInLocal()
  }
  
//  func syncWhenTaskEdittedInLocal(fetchedTasks: Observable<[TaskItem]>) {
//    let realm = try! Realm()
//    let tasks = realm.objects(TaskItem.self)
//
//    Observable.arrayWithChangeset(from: tasks)
//      .map { (arr, changes) -> [TaskItem] in
//        if let changes = changes, let updatedIndex = changes.updated.first {
//          return [arr[updatedIndex]]
//        }
//        return []
//      }
//      .flatMap { taskArr -> Observable<TaskItem> in
//        if let task = taskArr.first {
//          return self.issueService.editServerTask(newTitle: task.title,
//                                      newBody: task.body ?? "",
//                                      newState: task.checked,
//                                      exTask: task)
//        }
//        return Observable<TaskItem>.empty()
//      }.subscribe {
//        print("update task on Server succeed")
//      }.disposed(by: bag)
//  }
//
//  func syncWhenTaskCreatedInLocal() {
//    let realm = try! Realm()
//    let tasks = realm.objects(TaskItem.self)
//
//    Observable.arrayWithChangeset(from: tasks)
//      .map { (arr, changes) -> [TaskItem] in
//        if let changes = changes, let createdIndex = changes.inserted.first {
//          return [arr[createdIndex]]
//        }
//        return []
//      }
//      .flatMap { taskArr -> Observable<TaskItem> in
//        if let task = taskArr.first {
//          return self.issueService.createIssue(title: task.title,
//                                               body: task.body ?? "",
//                                               repo: task.repository!)
//        }
//        return Observable<TaskItem>.empty()
//      }.subscribe {
//        print("update task on Server succeed")
//      }.disposed(by: bag)
//  }
  
  //기존에 없는 것이면 로컬에 추가해주기
  func syncLocalWithNewServerTask(fetchedTasks: Observable<[TaskItem]>) -> Observable<[TaskItem]> {
    return fetchedTasks
      //서버에만 있는 새로운 것을 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.addNewTask(fetchedTasks: $0)
      }
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
    }
  }
  
  //기존의 것중에 서버가 최신인 경우 로컬 변형
  func syncLocalWithExistingServerTask(fetchedTasks: Observable<[TaskItem]>) -> Observable<[TaskItem]> {
    return fetchedTasks
      //기존의 것 중 서버가 최신인것만 필터링해서 업데이트
      .flatMap { [unowned self] in
        self.localTaskService.updateOldLocal(fetchedTasks: $0)
      }
      //업데이트 완료시점 확인
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
    }
  }
  
  //로컬에서 생성한 경우 서버버전 Date 로 바꾸기
  func syncLocalDateToServerDate(fetchedTasks: Observable<[TaskItem]>) -> Observable<[TaskItem]> {
    //로컬에서 생성된 것 필터링
    return self.localTaskService.getLocalCreated()
      //서버에 새 이슈 생성
      .flatMap({ [unowned self] in
        self.issueService.createIssue(title: $0.title, body: $0.body ?? "", repo: $0.repository!)
      })
      //서버에서 새로 생성된 이슈의 Date로 로컬 변경
      .flatMap { [unowned self] in
        self.localTaskService.updateDate(newTask: $0)
      }
      //완료 시점 확인
      .reduce( [TaskItem](), accumulator: { (arr, task) in
        return arr + [task]
      })
  }
  
  //기존의 것중에 로컬이 최신인 경우 로컬에 표식을 변형해서 sync 되도록하기
  func syncServerWithExistingLocalTask(fetchedTasks: Observable<[TaskItem]>) -> Observable<[TaskItem]> {
      return fetchedTasks
        //기존의 것 중 로컬이 최신인것만 필터링
        .flatMap { [unowned self] in
          self.localTaskService.getRecentLocal(fetchedTasks: $0)
        }
        //서버 업데이트 요청
        .flatMap { [unowned self] in
          self.issueService.editServerTask(newTitle: $0.title, newBody: $0.body ?? "", newState: $0.checked, exTask: $0)
        }
        //업데이트 완료시점 확인
        .reduce([TaskItem]()) { arr, task in
          return arr + [task]
      }
  }
}
