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
      for task in tasks {
        if let exTask = realm.objects(TaskItem.self).filter("uid == \(task.uid)").first {
          try realm.write {
            exTask.title = task.title
            exTask.body = task.body
            exTask.checked = task.checked
          }
        } else {
          try realm.write {
            realm.add(task)
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
  func update(task: TaskItem, title: String) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      try realm.write {
        task.title = title
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
