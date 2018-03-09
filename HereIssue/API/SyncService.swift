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

//시퀀스를 받아서 처리하는 것들
//동기화 작업은 동기적으로
protocol SyncServiceRepresentable {
  func syncStart(fetchedTasks: Observable<[TaskItem]>)
  func updateOldServerWithNewLocal(fetchedTasks: Observable<[TaskItem]>)
  func updateOldServerWithRecentLocal(fetchedTasks: Observable<[TaskItem]>)
  func updateOldLocalWithNewServer(fetchedTasks: Observable<[TaskItem]>)
  func updateOldLocalWithRecentServer(fetchedTasks: Observable<[TaskItem]>)
}

class SyncService: SyncServiceRepresentable {
  
  private let bag = DisposeBag()
  private let issueService: IssueServiceRepresentable
  private let localTaskService: LocalTaskServiceType
  
  init(issueService: IssueServiceRepresentable, localTaskService: LocalTaskServiceType) {
    self.issueService = issueService
    self.localTaskService = localTaskService
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
  
  //동기적으로 sync 하기
  func syncStart(fetchedTasks: Observable<[TaskItem]>) {
    updateOldServerWithNewLocal(fetchedTasks: fetchedTasks)
  }
  
  //로컬에서 만든 이슈를 서버에 반영 후 로컬에 업데이트
  func updateOldServerWithNewLocal(fetchedTasks: Observable<[TaskItem]>) {
    
    //로컬에서 생성된 것 필터링
    self.localTaskService.getLocalCreated()
      //서버에 새 이슈 생성
      .flatMap({ [unowned self] in
        self.issueService.createIssueWithLocalTask(localTaskWithRef: $0)
      })
      //로컬에 기존 task 삭제
      .flatMap { [unowned self] in
        self.localTaskService.deleteTask(newTaskWithRef: $0)
      }
      //서버에서 생성한 새로운 이슈를 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.add(newTask: $0)
      }
      //완료 시점 확인
      .reduce( [TaskItem](), accumulator: { (arr, task) in
        return arr + [task]
      })
      .subscribe(onNext: { _ in
        print("updateOldServerWithNewLocal next")
      }, onCompleted: {
        self.updateOldServerWithRecentLocal(fetchedTasks: fetchedTasks)
        print("updateOldServerWithNewLocal complete")
      })
      .disposed(by: bag)
  }
  
  //기존의 것중에 로컬이 최신인 경우 서버 업데이트
  func updateOldServerWithRecentLocal(fetchedTasks: Observable<[TaskItem]>) {
    
    fetchedTasks
      //기존의 것 중 로컬이 최신인것만 필터링
      .flatMap { [unowned self] in
        self.localTaskService.getRecentLocal(fetchedTasks: $0)
      }
      .debug("---------recent----------")
      //서버 업데이트 요청
      .flatMap { [unowned self] in
        self.issueService.editServerTask(newTitle: $0.title,
                                         newBody: $0.body ?? "",
                                         newState: $0.checked,
                                         exTask: $0)
      }
      //업데이트 완료시점 확인
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
      }
      .subscribe(onNext: { _ in
        print("updateOldServerWithRecentLocal next")
      }, onCompleted: {
          self.updateOldLocalWithNewServer(fetchedTasks: fetchedTasks)
          print("updateOldServerWithRecentLocal complete")
      })
      .disposed(by: bag)
  }
  
  //기존에 없는 것이면 로컬에 추가해주기
  func updateOldLocalWithNewServer(fetchedTasks: Observable<[TaskItem]>) {
    print("updateOldLocalWithNewServer")
    
    fetchedTasks
      //서버에만 있는 새로운 것을 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.addNewTask(fetchedTasks: $0)
      }
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
      }
      .subscribe(onCompleted: {
          self.updateOldLocalWithRecentServer(fetchedTasks: fetchedTasks)
          print("updateOldLocalWithNewServer complete")
      })
      .disposed(by: bag)
  }
  
  //기존의 것중에 서버가 최신인 경우 로컬 변형
  func updateOldLocalWithRecentServer(fetchedTasks: Observable<[TaskItem]>) {
    fetchedTasks
      //기존의 것 중 서버가 최신인것만 필터링해서 업데이트
      .flatMap { [unowned self] in
        self.localTaskService.updateOldLocal(fetchedTasks: $0)
      }
      //업데이트 완료시점 확인
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
      }
      .subscribe(onCompleted: {
        print("updateOldLocalWithRecentServer complete")
      })
      .disposed(by: bag)
  }
  
}
