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
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem>
  
  func tasks() -> Observable<Results<TaskItem>>
  func repositories() -> Observable<Results<Repository>>
  func getRecentLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem>
  func updateOldLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem>
  func addNewTask(fetchedTasks: [TaskItem]) -> Observable<TaskItem>
  func getLocalCreated() -> Observable<LocalTaskService.TaskItemWithReference>
  func deleteTask(newTaskWithRef: LocalTaskService.TaskItemWithReference) -> Observable<TaskItem>
  func add(newTask: TaskItem) -> Observable<TaskItem>
  func observeEditTask() -> Observable<[TaskItem]>
  func observeCreateTask() -> Observable<[TaskItem]>
  func convertToTaskWithRef(task: TaskItem) -> Observable<LocalTaskService.TaskItemWithReference>
  func tasksForRepo(repoName: String) -> Observable<[TaskItem]>
}

class LocalTaskService: LocalTaskServiceType {
  typealias TaskItemReference = ThreadSafeReference<TaskItem>
  typealias TaskItemWithReference = (TaskItem, TaskItemReference)
  private let backgroundQueue = DispatchQueue(label: "samchon.background.realm")
  
  enum TaskServiceError: Error {
    case some(String)
    case creationFailed
    case updateFailed(TaskItem)
    case deletionFailed
    case toggleFailed(TaskItem)
  }
  
  //로컬에서 새로운 이슈 생성
  @discardableResult
  func createTask(title: String, body: String, repoName: String) -> Observable<TaskItem> {
    let result = withRealm("creating") { realm -> Observable<TaskItem> in
      let task = TaskItem()
      task.uid = UUID().uuidString
      task.owner = UserDefaults.loadUser()
      task.title = title
      task.body = body
      task.repository = getRepository(repoName: repoName)
      task.checked = "open"
      task.setDateWhenCreated()
      try realm.write {
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
  
  func tasksForRepo(repoName: String) -> Observable<[TaskItem]> {
    let result = withRealm("getting tasks") { realm -> Observable<[TaskItem]> in
      return Observable<[TaskItem]>.create({ (observer) -> Disposable in
        let tasks = realm.objects(TaskItem.self)
          .filter("repository.name = '\(repoName)'")
          .sorted(byKeyPath: "added", ascending: false)
          .toArray()
        observer.onNext(tasks)
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  //이슈의 모든 repository 불러오기
  func repositories() -> Observable<Results<Repository>> {
    let result = withRealm("getting repositories") { realm -> Observable<Results<Repository>> in
      let repositories = realm.objects(Repository.self)
      return Observable.collection(from: repositories)
    }
    return result ?? .empty()
  }
  
  func repoLists() -> Observable<[Repository]> {
    let result = withRealm("repoLists") { realm in
      return Observable<[Repository]>.create({ observer -> Disposable in
        let repos = realm.objects(Repository.self)
        let repoList = Array(Set(repos))
        observer.onNext(repoList)
        observer.onCompleted()
        return Disposables.create()
      })
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
          
          if let _ = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
          } else {
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
  
  //서버가 최신인 것 찾아서 로컬변형
  func updateOldLocal(fetchedTasks: [TaskItem]) -> Observable<TaskItem> {
    let result = withRealm("updateOldLocal") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        fetchedTasks.forEach { fetchedTask in
          if let localTask = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
            if localTask.updatedDate < fetchedTask.updatedDate {
              try! realm.write {
                localTask.title = fetchedTask.title
                localTask.body = fetchedTask.body
                localTask.added = fetchedTask.added
                localTask.checked = fetchedTask.checked
                localTask.number = fetchedTask.number
                localTask.owner = fetchedTask.owner
                localTask.repository = fetchedTask.repository
                localTask.updated = fetchedTask.updated
              }
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
  
  //로컬에서 생성된 것 찾기
  func getLocalCreated() -> Observable<TaskItemWithReference> {
    let result = withRealm("getLocalCreated") { realm in
      return Observable<TaskItemWithReference>.create({ observer -> Disposable in
        let localCreatedTasks = realm.objects(TaskItem.self).filter { $0.isServerGeneratedType == false }
        for task in localCreatedTasks {
          let ref = TaskItemReference(to: task)
          let tuple = (task, ref)
          observer.onNext(tuple)
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  func observeEditTask() -> Observable<[TaskItem]> {
    let result = withRealm("observeEditTask") { realm -> Observable<[TaskItem]> in
      let tasks = realm.objects(TaskItem.self)
      return Observable.arrayWithChangeset(from: tasks)
        .map { (arr, changes) -> [TaskItem] in
          if let changes = changes, let updatedIndex = changes.updated.first {
            return [arr[updatedIndex]]
          }
          return []
      }
    }
    return result ?? .empty()
  }
  
  func observeCreateTask() -> Observable<[TaskItem]> {
    let result = withRealm("observeCreateTask") { realm -> Observable<[TaskItem]> in
      let tasks = realm.objects(TaskItem.self)
      return Observable.arrayWithChangeset(from: tasks)
        .map { (arr, changes) -> [TaskItem] in
          if let changes = changes, let insertedIndex = changes.inserted.first {
            if !arr[insertedIndex].isServerGeneratedType {
              return [arr[insertedIndex]]
            }
            return []
          }
          return []
      }
    }
    return result ?? .empty()
  }
  
  func convertToTaskWithRef(task: TaskItem) -> Observable<TaskItemWithReference> {
    let result = withRealm("convertToTaskWithRef") { realm in
      return Observable<TaskItemWithReference>.create({ observer -> Disposable in
        if let insertedTask = realm.object(ofType: TaskItem.self, forPrimaryKey: task.uid) {
          let tuple = (insertedTask, TaskItemReference(to: insertedTask))
          observer.onNext(tuple)
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  //로컬에서 생성된 것을 지우고 서버에서 생성된 것을 추가
  @discardableResult
  func deleteTask(newTaskWithRef: TaskItemWithReference) -> Observable<TaskItem> {
    let result = withRealm("deleteTask") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        if let exTask = realm.resolve(newTaskWithRef.1) {
          try! realm.write {
            realm.delete(exTask)
          }
          observer.onNext(newTaskWithRef.0)
        }
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  @discardableResult
  func add(newTask: TaskItem) -> Observable<TaskItem> {
    let result = withRealm("add") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        try! realm.write {
          realm.add(newTask)
        }
        observer.onNext(newTask)
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
}

extension LocalTaskService {
  
  fileprivate func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
    do {
      let realm = try Realm()
      print(Thread.current, "thread \(#function)")
      return try action(realm)
    } catch let err {
      print("Failed \(operation) realm with error: \(err)")
      return nil
    }
  }
  
  fileprivate func writeOnBackground(action: @escaping (Realm) throws -> Void) -> Completable {
      return Completable.create { [unowned self] completable in
        self.backgroundQueue.async {
          do {
            let realm = try Realm()
            print(Thread.current, "thread \(#function)")
            if let _ = try? action(realm) {
              completable(.completed)
            }
            completable(.error(TaskServiceError.some(#function)))
          } catch {
            completable(.error(TaskServiceError.some(#function)))
          }
        }
        return Disposables.create()
      }
  }
  
  fileprivate func writeOnMain(action: @escaping (Realm) throws -> Void)
    -> Completable {
      return Completable.create { completable in
        DispatchQueue.main.async {
          do {
            let realm = try Realm()
            print(Thread.current, "thread \(#function)")
            if let _ = try? action(realm) {
              completable(.completed)
            }
            completable(.error(TaskServiceError.some(#function)))
          } catch {
            completable(.error(TaskServiceError.some(#function)))
          }
        }
        return Disposables.create()
      }
  }
}
