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
  func updateOldServerWithNewLocal(fetchedTasks: Observable<[TaskItem]>)
  func updateOldServerWithRecentLocal(fetchedTasks: Observable<[TaskItem]>)
  func updateOldLocalWithNewServer(fetchedTasks: Observable<[TaskItem]>)
  func updateOldLocalWithRecentServer(fetchedTasks: Observable<[TaskItem]>)
  var running: BehaviorRelay<Bool> { get }
}

class SyncService: SyncServiceRepresentable {
  
  private let bag = DisposeBag()
  private let issueService: IssueServiceRepresentable
  private let localTaskService: LocalTaskServiceType
  let running = BehaviorRelay<Bool>(value: false)
  
  init(issueService: IssueServiceRepresentable, localTaskService: LocalTaskServiceType) {
    self.issueService = issueService
    self.localTaskService = localTaskService
  }
  
  func syncWhenTaskEdittedInLocal() {
    print("-------eidt realtime---------")
    localTaskService.observeEditTask()
      .flatMap { taskArr -> Observable<TaskItem> in
        if let task = taskArr.first {
          print(task, "-------------------------realtime edit task----------------------")
          return self.issueService.editServerTask(newTitle: task.title,
                                      newBody: task.body ?? "",
                                      newState: task.checked,
                                      exTask: task)
        }
        return Observable<TaskItem>.empty()
      }.subscribe(onNext: { [unowned self] _ in
        self.running.accept(false)
      }, onCompleted: {
        self.running.accept(false)
      })
      .disposed(by: bag)
  }

  func syncWhenTaskCreatedInLocal() {
    print("-------create realtime---------")
    localTaskService.observeCreateTask()
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
        self.localTaskService.deleteTask(newTaskWithRef: $0)
      }
      //서버에서 생성한 새로운 이슈를 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.add(newTask: $0)
      }.subscribe(onNext: { [unowned self] _ in
        self.running.accept(false)
        }, onCompleted: {
          self.running.accept(false)
      })
      .disposed(by: bag)
  }
  
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
        self.running.accept(true)
      }, onCompleted: {
        print("updateOldServerWithNewLocal complete")
        self.updateOldServerWithRecentLocal(fetchedTasks: fetchedTasks)
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
        self.running.accept(true)
      }, onCompleted: {
        print("updateOldServerWithRecentLocal complete")
          self.updateOldLocalWithNewServer(fetchedTasks: fetchedTasks)
      })
      .disposed(by: bag)
  }
  
  //기존에 없는 것이면 로컬에 추가해주기
  func updateOldLocalWithNewServer(fetchedTasks: Observable<[TaskItem]>) {
    fetchedTasks
      //서버에만 있는 새로운 것을 로컬에 추가
      .flatMap { [unowned self] in
        self.localTaskService.addNewTask(fetchedTasks: $0)
      }
      .reduce([TaskItem]()) { arr, task in
        return arr + [task]
      }
      .subscribe(onNext: { _ in
        self.running.accept(true)
      }, onCompleted: {
        print("updateOldLocalWithNewServer complete")
        self.updateOldLocalWithRecentServer(fetchedTasks: fetchedTasks)
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
      .subscribe(onNext: { _ in
        self.running.accept(true)
      }, onCompleted: {
        print("updateOldLocalWithRecentServer complete")
        self.running.accept(false)
        self.syncWhenTaskEdittedInLocal()
        self.syncWhenTaskCreatedInLocal()
      })
      .disposed(by: bag)
  }
  
}
