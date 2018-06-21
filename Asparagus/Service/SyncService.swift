//
//  SyncService.swift
//  Asparagus
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
  func syncStart()
  func updateOldServerWithNewLocal()
  func updateOldServerWithRecentLocal()
  func updateOldLocalWithNewServer()
  func updateOldLocalWithRecentServer()
  func realTimeSync()
  var running: BehaviorSubject<Bool> { get }
}

class SyncService: SyncServiceRepresentable {
  
  private let bag = DisposeBag()
  private let issueService: IssueServiceRepresentable
  private let localTaskService: LocalTaskService
  let running = BehaviorSubject<Bool>(value: false)
  
  init(issueService: IssueServiceRepresentable, localTaskService: LocalTaskService) {
    self.issueService = issueService
    self.localTaskService = localTaskService
  }
  
  func syncWhenTaskEdittedInLocal() {
    print("-------edit realtime---------")
    localTaskService.observeEditTask()
      .filter{ $0.count > 0 }
      .observeOn(MainScheduler.instance)
      .flatMap { taskArr -> Observable<TaskItem> in
        if let task = taskArr.first {
          return self.issueService.editServerTask(newTitle: task.title,
                                      newBody: task.body ?? "",
                                      newState: task.checked,
                                      newLabels: task.labels.toArray().map { $0.name },
                                      newAssignees: task.assignees.toArray().map { $0.name },
                                      exTask: task)
        }
        return Observable<TaskItem>.empty()
      }
      .subscribe()
      .disposed(by: bag)
  }

  func syncWhenTaskCreatedInLocal() {
    print("-------create realtime---------")
    localTaskService.observeCreateTask()
      .filter{ $0.count > 0 }
      .distinctUntilChanged({ (taskArr1, taskArr2) -> Bool in
        return taskArr1.first!.uid == taskArr2.first!.uid
      })
      .observeOn(MainScheduler.instance)
      .flatMap({ [unowned self] in
        return self.localTaskService.convertToTaskWithRef(task: $0.first!)
      })
      //서버에 새 이슈 생성
      .flatMap({ [unowned self] in
        return self.issueService.createIssueWithLocalTask(localTaskWithRef: $0)
      })
      .filter{ !$0.1.1.isInvalidated }
      //서버에서 생성한 새로운 이슈를 로컬에 추가
      .flatMap { [unowned self] in
        return self.localTaskService.addTask(newTaskWithOldRef: $0)
      }
      //로컬에 기존 task 삭제
      .flatMap { [unowned self] in
        return self.localTaskService.fakeDeleteOldTask(oldTaskWithRef: $0)
      }
      //업데이트 완료시점 확인
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
      }
      .subscribe()
      .disposed(by: bag)
  }
  
  func realTimeSync() {
    syncWhenTaskCreatedInLocal()
    syncWhenTaskEdittedInLocal()
  }
  
  func syncStart() {
    self.running.onNext(true)
    
    issueService.fetchAllIssues(page: 1)
      .share(replay: 1, scope: .whileConnected)
      .flatMap { self.localTaskService.seperateSequence(fetchedTasks: $0)}
      .subscribe(onCompleted: { [unowned self] in
        self.seperateLocalTasks()
      })
      .disposed(by: bag)
  }
  
  func seperateLocalTasks() {
    localTaskService.seperateLocalTasks()
      .subscribe(onCompleted: { [unowned self] in
        print("seperateLocalTasks complete")
        self.deleteLocalTasks()
      })
      .disposed(by: bag)
  }
  
  func deleteLocalTasks() {
    localTaskService.getLocalDeleted()
      .flatMap { [unowned self] in
        self.localTaskService.deleteOldTask(oldTaskWithRef: $0)
      }
      .take(localTaskService.deletedLocalDict.count)
      .reduce([TaskItem]()) { (arr, task) in
        return arr + [task]
      }
      .subscribe(onCompleted: {
        print("deleteLocalTasks complete")
        self.updateOldServerWithNewLocal()
      })
      .disposed(by: bag)
  }
  
  //로컬에서 만든 이슈를 서버에 반영 후 로컬에 업데이트
  func updateOldServerWithNewLocal() {
    //로컬에서 생성된 것 필터링
    self.localTaskService.getLocalCreated()
      //서버에 새 이슈 생성
      .flatMap({ [unowned self] in
        self.issueService.createIssueWithLocalTask(localTaskWithRef: $0)
      })
      .take(localTaskService.createdLocalDict.count)
      //serverTask와 localTask의 uid 다르므로 먼저 넣어도 됨
      .flatMap { [unowned self] in
        self.localTaskService.addTask(newTaskWithOldRef: $0)
      }
      //localTask 삭제
      .flatMap { [unowned self] in
        self.localTaskService.deleteOldTask(oldTaskWithRef: $0)
      }
      //완료 시점 확인
      .reduce( [TaskItem](), accumulator: { (arr, task) in
        return arr + [task]
      })
      .subscribe(onNext: { _ in
        self.running.onNext(true)
      }, onCompleted: {
        print("updateOldServerWithNewLocal complete")
        self.updateOldServerWithRecentLocal()
      })
      .disposed(by: bag)
  }
  
  //기존의 것중에 로컬이 최신인 경우 서버 업데이트
  func updateOldServerWithRecentLocal() {
    localTaskService.getRecentLocal()
      .flatMap { [unowned self] in
        self.issueService.editServerTask(newTitle: $0.title,
                                         newBody: $0.body ?? "",
                                         newState: $0.checked,
                                         newLabels: $0.labels.toArray().map{ $0.name },
                                         newAssignees: $0.assignees.toArray().map{ $0.name },
                                         exTask: $0)
      }
      .take(localTaskService.recentLocalDict.count)
      .subscribe(onNext: { _ in
        self.running.onNext(true)
      }, onCompleted: {
        print("updateOldServerWithRecentLocal complete")
          self.updateOldLocalWithNewServer()
      })
      .disposed(by: bag)
  }
  
  //기존에 없는 것이면 로컬에 추가해주기
  func updateOldLocalWithNewServer() {
    localTaskService.getNewServer()
      .flatMap { [unowned self] in
        self.localTaskService.add(newTask: $0)
      }
      .take(localTaskService.newServerDict.count)
      .subscribe(onNext: { _ in
        self.running.onNext(true)
      }, onCompleted: {
        print("updateOldLocalWithNewServer complete")
        self.updateOldLocalWithRecentServer()
      })
      .disposed(by: bag)
  }
  
  //기존의 것중에 서버가 최신인 경우 로컬 변형
  func updateOldLocalWithRecentServer() {
    localTaskService.getRecentServer()
      //로컬에 기존 task 삭제
      .take(localTaskService.recentServerDict.count)
      .distinctUntilChanged({ (tuple1, tuple2) -> Bool in
        return tuple1.0.uid == tuple2.0.uid
      })
      .filter{ !$0.1.1.isInvalidated }
      .flatMap { [unowned self] in
        self.localTaskService.updateTask(newTaskWithOldRef: $0)
      }
      .subscribe(onNext: { _ in
        self.running.onNext(true)
      }, onCompleted: {
        print("updateOldLocalWithRecentServer complete")
        self.running.onNext(false)
      })
      .disposed(by: bag)
  }
  
}
