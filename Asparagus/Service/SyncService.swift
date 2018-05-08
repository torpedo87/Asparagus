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
  func syncStart(fetchedTasks: Observable<[TaskItem]>)
  func updateOldServerWithNewLocal()
  func updateOldServerWithRecentLocal()
  func updateOldLocalWithNewServer()
  func updateOldLocalWithRecentServer()
  var running: PublishSubject<Bool> { get }
}

class SyncService: SyncServiceRepresentable {
  
  private let bag = DisposeBag()
  private let issueService: IssueServiceRepresentable
  private let localTaskService: LocalTaskServiceType
  let running = PublishSubject<Bool>()
  
  init(issueService: IssueServiceRepresentable, localTaskService: LocalTaskServiceType) {
    self.issueService = issueService
    self.localTaskService = localTaskService
  }
  
  func syncWhenTaskEdittedInLocal() {
    print("-------edit realtime---------")
    localTaskService.observeEditTask()
      .subscribeOn(MainScheduler.instance)
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
      }.subscribe(onNext: { [unowned self] _ in
        self.running.onNext(false)
      }, onCompleted: {
        print("realtime edit complete")
        self.running.onNext(false)
      })
      .disposed(by: bag)
  }

  func syncWhenTaskCreatedInLocal() {
    print("-------create realtime---------")
    localTaskService.observeCreateTask()
      .subscribeOn(MainScheduler.instance)
      .filter { $0.count > 0 }
      .flatMap({ [unowned self] in
        self.localTaskService.convertToTaskWithRef(task: $0.first!)
      })
      //서버에 새 이슈 생성
      .flatMap({ [unowned self] in
        self.issueService.createIssueWithLocalTask(localTaskWithRef: $0)
      })
      //로컬에 기존 task 삭제
      .flatMap { [unowned self] in
        self.localTaskService.deleteTask(newTaskWithOldRef: $0)
      }
      //서버에서 생성한 새로운 이슈를 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.add(newTask: $0)
      }
      //업데이트 완료시점 확인
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
      }
      .subscribe(onNext: { [unowned self] _ in
        self.running.onNext(false)
        }, onCompleted: {
          print("realtime create complete")
          self.running.onNext(false)
      })
      .disposed(by: bag)
  }
  
  func syncStart(fetchedTasks: Observable<[TaskItem]>) {
    self.running.onNext(true)
    fetchedTasks
      .flatMap { self.localTaskService.seperateSequence(fetchedTasks: $0) }
      .subscribe(onCompleted: {
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
      .take(localTaskService.localCreatedCount())
      //로컬에 기존 task 삭제
      .flatMap { [unowned self] in
        self.localTaskService.deleteTask(newTaskWithOldRef: $0)
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
      .flatMap { [unowned self] in
        self.localTaskService.deleteTask(newTaskWithOldRef: $0)
      }
      .take(localTaskService.recentServerDict.count)
      //서버에서 생성한 새로운 이슈를 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.add(newTask: $0)
      }
      .subscribe(onNext: { _ in
        self.running.onNext(true)
      }, onCompleted: {
        print("updateOldLocalWithRecentServer complete")
        self.running.onNext(false)
        //self.syncWhenTaskEdittedInLocal()
        //self.syncWhenTaskCreatedInLocal()
      })
      .disposed(by: bag)
  }
  
}
