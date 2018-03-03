//
//  TaskService.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm

struct TaskService: TaskServiceType {
  init() {
    do {
      let realm = try Realm()
      if realm.objects(TaskItem.self).count == 0 {
        ["할일 2",
         "할일 1"].forEach {
          self.createTask(title: $0)
        }
      }
    } catch _ {
    }
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
  
  func fetchTasks(tasks: [TaskItem]) -> Observable<[TaskItem]> {
    let result = withRealm("fetch") { realm -> Observable<[TaskItem]> in
      for serverTask in tasks {
        //기존에 있는 task
        if let localTask = realm.objects(TaskItem.self).filter("uid == \(serverTask.uid)").first {
          //서버가 최신일때
          if serverTask.getUpdatedDate() > localTask.getUpdatedDate() {
            try realm.write {
              localTask.title = serverTask.title
              localTask.body = serverTask.body
              localTask.added = serverTask.added
              localTask.updated = serverTask.updated
            }
          }
        } else {
          //로컬에 없는 task
          try realm.write {
            serverTask.setDateWhenUpdated()
            realm.add(serverTask)
          }
        }
      }
      return .just(tasks)
    }
    return result ?? .error(TaskServiceError.fetchFailed)
  }
  
  @discardableResult
  func createTask(title: String) -> Observable<TaskItem> {
    let result = withRealm("creating") { realm -> Observable<TaskItem> in
      let task = TaskItem()
      task.title = title
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
  
  @discardableResult
  func delete(task: TaskItem) -> Observable<Void> {
    let result = withRealm("deleting") { realm-> Observable<Void> in
      try realm.write {
        realm.delete(task)
      }
      return .empty()
    }
    return result ?? .error(TaskServiceError.deletionFailed(task))
  }
  
  @discardableResult
  func update(task: TaskItem, title: String, body: String) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      try realm.write {
        task.title = title
        task.body = body
        task.setDateWhenUpdated()
      }
      return .just(task)
    }
    return result ?? .error(TaskServiceError.updateFailed(task))
  }
  
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
  
  func tasks() -> Observable<Results<TaskItem>> {
    let result = withRealm("getting tasks") { realm -> Observable<Results<TaskItem>> in
      let realm = try Realm()
      let tasks = realm.objects(TaskItem.self)
      return Observable.collection(from: tasks)
    }
    return result ?? .empty()
  }
}
