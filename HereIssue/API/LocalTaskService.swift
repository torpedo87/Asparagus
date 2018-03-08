//
//  LocalTaskService.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import RxRealm

protocol LocalTaskServiceType {
  
  @discardableResult
  func createTask(title: String, body: String, repoName: String) -> Observable<TaskItem>
  
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String) -> Observable<TaskItem>
  func updateAll(newTask: TaskItem) -> Observable<TaskItem>
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem>
  
  func tasks() -> Observable<Results<TaskItem>>
  func repositories() -> Observable<Results<Repository>>
  func getRecentLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem>
  func updateOldLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem>
  func addNewTask(fetchedTasks: [TaskItem]) -> Observable<TaskItem>
  func getLocalCreated() -> Observable<TaskItem>
  
}

struct LocalTaskService: LocalTaskServiceType {
  
  enum TaskServiceError: Error {
    case creationFailed
    case updateFailed(TaskItem)
    case deletionFailed(TaskItem)
    case toggleFailed(TaskItem)
  }
  
  init() {

  }
  
  fileprivate func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
    do {
      let realm = try Realm()
      return try action(realm)
    } catch let err {
      print("Failed \(operation) realm with error: \(err)")
      return nil
    }
  }
  
  //로컬에서 새로운 이슈 생성
  @discardableResult
  func createTask(title: String, body: String, repoName: String) -> Observable<TaskItem> {
    let result = withRealm("creating") { realm -> Observable<TaskItem> in
      let task = TaskItem()
      task.title = title
      task.body = body
      task.repository = getRepository(repoName: repoName)
      task.checked = "open"
      task.setDateWhenCreated()
      try realm.write {
        task.uid = (realm.objects(TaskItem.self).max(ofProperty: "uid") ?? 0) + 1
        realm.add(task)
      }
      return .just(task)
    }
    return result ?? .error(TaskServiceError.creationFailed)
  }
  
  //title, body 수정
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      try realm.write {
        exTask.title = newTitle
        exTask.body = newBody
        exTask.setDateWhenUpdated()
      }
      return .just(exTask)
    }
    return result ?? .error(TaskServiceError.updateFailed(exTask))
  }
  
  //이슈 close or open
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem> {
    let result = withRealm("toggling") { realm -> Observable<TaskItem> in
      try realm.write {
        if task.checked == "open" {
          task.checked = "closed"
        } else {
          task.checked = "open"
        }
        task.setDateWhenUpdated()
      }
      return .just(task)
    }
    return result ?? .error(TaskServiceError.toggleFailed(task))
  }
  
  //로컬에 저장된 모든 task 불러오기
  func tasks() -> Observable<Results<TaskItem>> {
    print("------realmfile-------", Realm.Configuration.defaultConfiguration.fileURL)
    let result = withRealm("getting tasks") { realm -> Observable<Results<TaskItem>> in
      let realm = try Realm()
      let tasks = realm.objects(TaskItem.self)
      return Observable.collection(from: tasks)
    }
    return result ?? .empty()
  }
  
  //이슈의 모든 repository 불러오기
  func repositories() -> Observable<Results<Repository>> {
    let result = withRealm("getting repositories") { realm -> Observable<Results<Repository>> in
      let realm = try Realm()
      let repositories = realm.objects(Repository.self)
      return Observable.collection(from: repositories)
    }
    return result ?? .empty()
  }
  
  //helper
  func getRepository(repoName: String) -> Repository {
    let realm = try! Realm()
    let repositories = realm.objects(Repository.self).filter { $0.name == repoName }
    return repositories.first!
  }
  
  //서버에서 생성한 이슈를 찾아서 로컬에 추가
  func addNewTask(fetchedTasks: [TaskItem]) -> Observable<TaskItem> {
    let result = withRealm("addNewTask") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        fetchedTasks.forEach { fetchedTask in
          if realm.objects(TaskItem.self).filter("uid = \(fetchedTask.uid)").count == 0 {
            try! realm.write {
              realm.add(fetchedTask)
            }
            observer.onNext(fetchedTask)
          }
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  //로컬이 최신인 것만 필터링
  func getRecentLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem> {
    let result = withRealm("getRecentLocal") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        fetchedTasks.forEach { fetchedTask in
          if let localTask = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
            if localTask.updatedDate > fetchedTask.updatedDate {
              observer.onNext(localTask)
            }
          }
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  //서버가 최신인 것 찾아서 로컬을 변형
  func updateOldLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem> {
    let result = withRealm("updateOldLocal") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        fetchedTasks.forEach { fetchedTask in
          if let localTask = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
            if localTask.updatedDate < fetchedTask.updatedDate {
              self.updateAll(newTask: fetchedTask)
              observer.onNext(localTask)
            }
          }
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  @discardableResult
  func updateAll(newTask: TaskItem) -> Observable<TaskItem> {
    let result = withRealm("updateAll") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        if let exTask = realm.objects(TaskItem.self).filter("uid = \(newTask.uid)").first {
          try! realm.write {
            exTask.title = newTask.title
            exTask.body = newTask.body
            exTask.added = newTask.added
            exTask.checked = newTask.checked
            exTask.number = newTask.number
            exTask.owner = newTask.owner
            exTask.repository = newTask.repository
            exTask.uid = newTask.uid
            exTask.updated = newTask.updated
          }
          observer.onNext(exTask)
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  //로컬에서 생성된 것 찾기
  func getLocalCreated() -> Observable<TaskItem> {
    let result = withRealm("getLocalCreated") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        let localCreatedTasks = realm.objects(TaskItem.self).filter { $0.isServerGeneratedType == false }
        for task in localCreatedTasks {
          observer.onNext(task)
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  
}
