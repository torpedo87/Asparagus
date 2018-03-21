//
//  LocalTaskService.swift
//  Asparagus
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
  func createTask(title: String, body: String, repoName: String, tags: [String]) -> Observable<TaskItem>
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String, newTags: [String]) -> Observable<TaskItem>
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
  func tasksForTag(tagTitle: String) -> Observable<Results<TaskItem>>
  func tags() -> Observable<Results<Tag>>
  func openTasks() -> Observable<Results<TaskItem>>
}

class LocalTaskService: LocalTaskServiceType {
  typealias TaskItemReference = ThreadSafeReference<TaskItem>
  typealias TaskItemWithReference = (TaskItem, TaskItemReference)
  
  enum TaskServiceError: Error {
    case some(String)
    case creationFailed
    case updateFailed(TaskItem)
    case deletionFailed
    case toggleFailed(TaskItem)
  }
  
  //로컬에서 새로운 이슈 생성
  @discardableResult
  func createTask(title: String, body: String, repoName: String, tags: [String]) -> Observable<TaskItem> {
    let result = withRealm("creating") { realm -> Observable<TaskItem> in
      let task = TaskItem()
      task.uid = UUID().uuidString
      task.owner = UserDefaults.loadUser() ?? nil
      task.title = title
      task.body = body
      task.checked = "open"
      task.setDateWhenCreated()
      try realm.write {
        //레퍼지토리 있으면 레퍼지토리 태그 추가
        if let repo = getRepository(repoName: repoName) {
          task.repository = repo
          let group = defaultTag(realm: realm, tagTitle: repoName)
          group.isCreatedInServer = true
          group.tasks.append(task)
        }
        //태그 있으면 추가
        if tags.count > 0 {
          for tag in tags {
            let group = defaultTag(realm: realm, tagTitle: tag)
            group.isCreatedInServer = true
            group.tasks.append(task)
          }
        } else {
          realm.add(task)
        }
        print(Thread.current, "write thread \(#function)")
      }
      if let managedTask = realm.object(ofType: TaskItem.self, forPrimaryKey: task.uid) {
        return .just(managedTask)
      }
      return .empty()
    }
    return result ?? .error(TaskServiceError.creationFailed)
  }
  
  //title, body 수정
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String, newTags: [String]) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      realm.writeAsync(obj: exTask, block: { (realm, exTask) in
        if let exTask = exTask {
          exTask.title = newTitle
          exTask.body = newBody
          exTask.setDateWhenUpdated()
          self.deleteTaskIndeletedTags(realm: realm, exTask: exTask, newTags: newTags)
          self.addTaskInCreatedTags(realm: realm, exTask: exTask, newTags: newTags)
        }
        print(Thread.current, "write thread \(#function)")
      })
      return .just(exTask)
    }
    return result ?? .error(TaskServiceError.updateFailed(exTask))
  }
  
  func deleteTaskIndeletedTags(realm: Realm, exTask: TaskItem, newTags: [String]) {
    let exTags = exTask.tag.toArray().map{ $0.title }
    var deletedTags = [String]()
    for exTag in exTags {
      if !newTags.contains(exTag) {
        deletedTags.append(exTag)
      }
    }
    for deletedTag in deletedTags {
      let group = defaultTag(realm: realm, tagTitle: deletedTag)
      let i = findIndex(tasks: group.tasks.toArray(), exTask: exTask)
      group.tasks.remove(at: i)
    }
  }
  
  func addTaskInCreatedTags(realm: Realm, exTask: TaskItem, newTags: [String]) {
    let exTags = exTask.tag.toArray().map{ $0.title }
    var createdTags = [String]()
    for newTag in newTags {
      if !exTags.contains(newTag) {
        createdTags.append(newTag)
      }
    }
    for createdTag in createdTags {
      let group = defaultTag(realm: realm, tagTitle: createdTag)
      group.tasks.append(exTask)
    }
  }
  
  func findIndex(tasks: [TaskItem], exTask: TaskItem) -> Int {
    for i in 0..<tasks.count {
      if tasks[i].uid == exTask.uid {
        return i
      }
    }
    return -1
  }
  
  //이슈 close or open
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem> {
    let result = withRealm("toggling") { realm -> Observable<TaskItem> in
      realm.writeAsync(obj: task, block: { (realm, task) in
        if task?.checked == "open" {
          task?.checked = "closed"
        } else {
          task?.checked = "open"
        }
        task?.setDateWhenUpdated()
        print(Thread.current, "write thread \(#function)")
      })
      return .just(task)
    }
    return result ?? .error(TaskServiceError.toggleFailed(task))
  }
  
  //로컬에 저장된 모든 task 불러오기
  func tasks() -> Observable<Results<TaskItem>> {
    let result = withRealm("getting tasks") { realm -> Observable<Results<TaskItem>> in
      let tasks = realm.objects(TaskItem.self)
      return Observable.collection(from: tasks)
    }
    return result ?? .empty()
  }
  
  func openTasks() -> Observable<Results<TaskItem>> {
    let result = withRealm("getting tasks") { realm -> Observable<Results<TaskItem>> in
      let tasks = realm.objects(TaskItem.self).filter("checked = 'open'")
      return Observable.collection(from: tasks)
    }
    return result ?? .empty()
  }
  
  func tags() -> Observable<Results<Tag>> {
    print("------realmfile-------", RealmConfig.main.configuration.fileURL)
    let result = withRealm("getting groups") { realm -> Observable<Results<Tag>> in
      let tags = realm.objects(Tag.self)
      return Observable.collection(from: tags)
    }
    return result ?? .empty()
  }
  
  func tasksForTag(tagTitle: String) -> Observable<Results<TaskItem>> {
    let result = withRealm("tasksForTag") { realm -> Observable<Results<TaskItem>> in
      if let tag = realm.object(ofType: Tag.self, forPrimaryKey: tagTitle) {
        let tasks = tag.tasks
          .sorted(byKeyPath: "added", ascending: false)
        return Observable.collection(from: tasks)
      }
      return Observable.empty()
    }
    return result ?? .empty()
  }
  
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
  func getRepository(repoName: String) -> Repository? {
    let realm = try! Realm(configuration: RealmConfig.main.configuration)
    let repositories = realm.objects(Repository.self).filter { $0.name == repoName }
    return repositories.first ?? nil
  }
  
  //서버에서 생성한 이슈를 찾아서 로컬에 추가
  func addNewTask(fetchedTasks: [TaskItem]) -> Observable<TaskItem> {
    let result = withRealm("addNewTask") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        fetchedTasks.forEach { fetchedTask in
          if let _ = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
          } else {
            try! realm.write {
              let group = self.defaultTag(realm: realm, tagTitle: fetchedTask.repository!.name)
              group.isCreatedInServer = true
              group.tasks.append(fetchedTask)
              print(Thread.current, "write thread \(#function)")
            }
            if let managedTask = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
              observer.onNext(managedTask)
            }
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
              realm.writeAsync(obj: localTask, block: { (realm, localTask) in
                localTask?.title = fetchedTask.title
                localTask?.body = fetchedTask.body
                localTask?.added = fetchedTask.added
                localTask?.checked = fetchedTask.checked
                localTask?.number = fetchedTask.number
                localTask?.owner = fetchedTask.owner
                localTask?.repository = fetchedTask.repository
                localTask?.updated = fetchedTask.updated
                print(Thread.current, "write thread \(#function)")
              })
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
        let localCreatedTasks = realm.objects(TaskItem.self)
          .filter { !$0.isServerGeneratedType && $0.repository != nil }
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
            let task = arr[updatedIndex]
            if task.isServerGeneratedType {
              return [task]
            }
            return []
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
            let task = arr[insertedIndex]
            if !task.isServerGeneratedType && task.tag.first!.isCreatedInServer {
              return [task]
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
          realm.writeAsync(obj: exTask, block: { (realm, exTask) in
            realm.delete(exTask!)
            print(Thread.current, "write thread \(#function)")
          })
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
          let tag = self.defaultTag(realm: realm, tagTitle: newTask.repository!.name)
          tag.isCreatedInServer = true
          tag.tasks.append(newTask)
          print(Thread.current, "write thread \(#function)")
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
      let realm = try Realm(configuration: RealmConfig.main.configuration)
      return try action(realm)
    } catch let err {
      print("Failed \(operation) realm with error: \(err)")
      return nil
    }
  }
  
  func defaultTag(realm: Realm, tagTitle: String) -> Tag {
    if let tag = realm.object(ofType: Tag.self, forPrimaryKey: tagTitle) {
      return tag
    }
    let newTag = Tag()
    newTag.title = tagTitle
    newTag.setDateWhenCreated()
    realm.add(newTag)
    return realm.object(ofType: Tag.self, forPrimaryKey: tagTitle)!
  }
  
  static func migrate(_ migration: Migration, fileSchemaVersion: UInt64) {
//    if fileSchemaVersion == 1 {
//      let dateFormatter = DateFormatter()
//      dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
//      dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//      let now = dateFormatter.string(from: Date())
//      migration.enumerateObjects(ofType: "TaskItem", { (oldTask, newTask) in
//        if let newTask = newTask {
//          if let date = newTask["updated"] as? String {
//            if date.compare(now) == .orderedDescending {
//
//            } else {
//
//            }
//          }
//        }
//      })
//    }
  }
  
  static func copyInitialData(_ from: URL, to: URL) {
    let copy = {
      _ = try? FileManager.default.removeItem(at: to)
      try! FileManager.default.copyItem(at: from, to: to)
    }
    let exists: Bool
    do {
      exists = try to.checkPromisedItemIsReachable()
    } catch {
      copy()
      return
    }
    if !exists {
      copy()
    }
  }
}

extension Realm {
  func writeAsync<T : ThreadConfined>(obj: T, errorHandler: @escaping ((_ error : Swift.Error) -> Void) = { _ in return }, block: @escaping ((Realm, T?) -> Void)) {
    let wrappedObj = ThreadSafeReference(to: obj)
    let config = self.configuration
    DispatchQueue(label: "background").async {
      autoreleasepool {
        do {
          let realm = try Realm(configuration: config)
          let obj = realm.resolve(wrappedObj)
          try realm.write {
            block(realm, obj)
          }
        }
        catch {
          errorHandler(error)
        }
      }
    }
  }
}
