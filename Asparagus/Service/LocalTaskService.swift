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

// read 작업시 threadsafe 필요없음
// realm managed object는 thread 전환 시 통과할 수 없으므로 threadsafe 타입을 사용해야 함
// realm noti 는 main thread 에서

protocol LocalTaskServiceType {
  var recentServerDict: [String:(TaskItem, LocalTaskService.TaskItemWithReference)] { get }
  var recentLocalDict: [String:TaskItem] { get }
  var newServerDict: [String:TaskItem] { get }
  @discardableResult
  func createBlankTask(title: String) -> Observable<TaskItem>
  @discardableResult
  func createSubTask(title: String, superTask: TaskItem) -> Observable<SubTask>
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String) -> Observable<TaskItem>
  func updateRepo(exTask: TaskItem, repo: Repository?) -> Observable<TaskItem>
  func updateTag(exTask: TaskItem, tag: Tag, mode: LocalTaskService.EditMode) -> Observable<TaskItem>
  func updateAssignee(exTask: TaskItem, assignee: Assignee, mode: LocalTaskService.EditMode) -> Observable<TaskItem>
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem>
  func toggle(task: SubTask) -> Observable<SubTask>
  func repositories() -> Observable<Results<Repository>>
  func getRecentLocal() -> Observable<TaskItem>
  func getRecentServer() -> Observable<(TaskItem, LocalTaskService.TaskItemWithReference)>
  func getNewServer() -> Observable<TaskItem>
  func seperateSequence(fetchedTasks: [TaskItem]) -> Completable
  func getLocalCreated() -> Observable<LocalTaskService.TaskItemWithReference>
  func deleteTask(newTaskWithOldRef: (TaskItem, LocalTaskService.TaskItemWithReference)) -> Observable<TaskItem>
  func add(newTask: TaskItem) -> Observable<TaskItem>
  func observeEditTask() -> Observable<[TaskItem]>
  func observeCreateTask() -> Observable<[TaskItem]>
  func convertToTaskWithRef(task: TaskItem) -> Observable<LocalTaskService.TaskItemWithReference>
  func tasksForTag(tagTitle: String) -> Observable<Results<TaskItem>>
  func tags() -> Observable<Results<Tag>>
  func localRepositories() -> Observable<Results<LocalRepository>>
  func subTasksForTask(task: TaskItem) -> Observable<Results<SubTask>>
  func tagsForTask(task: TaskItem) -> Observable<Results<Tag>>
  func getRepository(repoName: String) -> Repository?
  func tasksForAssignee(username: String) -> Observable<Results<TaskItem>>
  func tasksForLocalRepo(repoUid: String) -> Observable<Results<TaskItem>>
  func localTasks() -> Observable<Results<TaskItem>>
  func localCreatedCount() -> Int
  func deleteTaskOnMain(localTask: TaskItem) -> Observable<Void>
  func addTask(newTaskWithOldRef: (TaskItem, LocalTaskService.TaskItemWithReference)) -> Observable<LocalTaskService.TaskItemWithReference>
  func deleteOldTask(oldTaskWithRef: LocalTaskService.TaskItemWithReference) -> Observable<TaskItem>
  func updateTask(newTaskWithOldRef: (TaskItem, LocalTaskService.TaskItemWithReference)) -> Observable<TaskItem>
}

class LocalTaskService: LocalTaskServiceType {
  typealias TaskItemReference = ThreadSafeReference<TaskItem>
  typealias TaskItemWithReference = (TaskItem, TaskItemReference)
  var recentServerDict = [String:(TaskItem,TaskItemWithReference)]()
  var recentLocalDict = [String:TaskItem]()
  var newServerDict = [String:TaskItem]()
  let backgroundQueue = DispatchQueue(label: "background")
  
  enum TaskServiceError: Error {
    case some(String)
    case creationFailed
    case updateFailed(TaskItem)
    case deletionFailed
    case toggleFailed(TaskItem)
  }
  
  func createBlankTask(title: String) -> Observable<TaskItem> {
    let result = withRealm("creating") { realm -> Observable<TaskItem> in
      let task = TaskItem()
      task.uid = UUID().uuidString
      task.owner = UserDefaults.loadUser() ?? nil
      task.title = title
      task.checked = "open"
      task.setDateWhenCreated()
      try realm.write {
        realm.add(task)
        print(Thread.current, "write thread \(#function)")
      }
      return .just(task)
    }
    return result ?? .error(TaskServiceError.creationFailed)
  }
  
  @discardableResult
  func createSubTask(title: String, superTask: TaskItem) -> Observable<SubTask> {
    let result = withRealm("creating") { realm -> Observable<SubTask> in
      let subTask = SubTask()
      subTask.uid = UUID().uuidString
      subTask.title = title
      subTask.checked = "open"
      subTask.setDateWhenCreated()
      try realm.write {
        if let superTask = realm.object(ofType: TaskItem.self, forPrimaryKey: superTask.uid) {
          superTask.subTasks.append(subTask)
        }
        print(Thread.current, "write thread \(#function)")
      }
      return .just(subTask)
    }
    return result ?? .empty()
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
      print(Thread.current, "write thread \(#function)")
      return .just(exTask)
    }
    return result ?? .error(TaskServiceError.updateFailed(exTask))
  }
  
  @discardableResult
  func updateRepo(exTask: TaskItem, repo: Repository? = nil) -> Observable<TaskItem> {
    let result = withRealm("updateRepo") { realm -> Observable<TaskItem> in
      var repoName = ""
      if let repo = repo {
        repoName = repo.name
      }
      try realm.write {
        exTask.setDateWhenUpdated()
        exTask.repository = self.getRepository(repoName: repoName)
      }
      return .just(exTask)
    }
    return result ?? .empty()
  }
  
  enum EditMode {
    case add
    case delete
  }
  
  func updateTag(exTask: TaskItem, tag: Tag, mode: EditMode) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      //파라미터의 tag는 Ref 없어서 thread 이동 불가
      let tagTitle = tag.title
      try realm.write {
        let group = self.defaultTag(realm: realm, tagTitle: tagTitle)
        switch mode {
        case .add: do {
          group.tasks.append(exTask)
          exTask.labels.append(Label(name: tagTitle))
          }
        case .delete: do {
          if let index = self.findIndex(tasks: group.tasks.toArray(), exTask: exTask) {
            group.tasks.remove(at: index)
          }
          
          if let index = self.findIndex(labels: exTask.labels.toArray(), exTagTitle: tagTitle) {
            exTask.labels.remove(at: index)
          }
          }
        }
        exTask.setDateWhenUpdated()
      }
      return .just(exTask)
    }
    return result ?? .empty()
  }
  
  func updateAssignee(exTask: TaskItem, assignee: Assignee, mode: EditMode) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      let assigneeName = assignee.name
      try realm.write {
        let group = self.defaultAssignee(realm: realm, assigneeName: assigneeName)
        switch mode {
        case .add: do {
          group.tasks.append(exTask)
          exTask.assignees.append(User(name: assigneeName))
          }
        case .delete: do {
          if let index = self.findIndex(tasks: group.tasks.toArray(), exTask: exTask) {
            group.tasks.remove(at: index)
          }
          
          if let index = self.findIndex(assignees: exTask.assignees.toArray(), username: assigneeName) {
            exTask.assignees.remove(at: index)
          }
          
          }
        }
        exTask.setDateWhenUpdated()
      }
      return .just(exTask)
    }
    return result ?? .empty()
  }
  
  func findIndex(tasks: [TaskItem], exTask: TaskItem) -> Int? {
    for i in 0..<tasks.count {
      if tasks[i].uid == exTask.uid {
        return i
      }
    }
    return nil
  }
  
  func findIndex(labels: [Label], exTagTitle: String) -> Int? {
    for i in 0..<labels.count {
      if labels[i].name == exTagTitle {
        return i
      }
    }
    return nil
  }
  
  func findIndex(assignees: [User], username: String) -> Int? {
    for i in 0..<assignees.count {
      if assignees[i].name == username {
        return i
      }
    }
    return nil
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
      print(Thread.current, "write thread \(#function)")
      return .just(task)
    }
    return result ?? .error(TaskServiceError.toggleFailed(task))
  }
  
  @discardableResult
  func toggle(task: SubTask) -> Observable<SubTask> {
    let result = withRealm("toggling") { realm -> Observable<SubTask> in
      try realm.write {
        if task.checked == "open" {
          task.checked = "closed"
        } else {
          task.checked = "open"
        }
      }
      
      print(Thread.current, "write thread \(#function)")
      return .just(task)
    }
    return result ?? .empty()
  }
  
  func tags() -> Observable<Results<Tag>> {
    let result = withRealm("tags") { realm -> Observable<Results<Tag>> in
      let tags = realm.objects(Tag.self)
      return Observable.collection(from: tags)
    }
    return result ?? .empty()
  }
  
  func localRepositories() -> Observable<Results<LocalRepository>> {
    let result = withRealm("localRepositories") { realm -> Observable<Results<LocalRepository>> in
      let localRepositories = realm.objects(LocalRepository.self)
      return Observable.collection(from: localRepositories)
    }
    return result ?? .empty()
  }
  
  func tagsForTask(task: TaskItem) -> Observable<Results<Tag>> {
    let result = withRealm("tagsForTask") { realm -> Observable<Results<Tag>> in
      if let singleTask = realm.object(ofType: TaskItem.self, forPrimaryKey: task.uid) {
        let tags = singleTask.tag.sorted(byKeyPath: "added", ascending: false)
        return Observable.collection(from: tags)
      }
      return .empty()
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
  
  func tasksForLocalRepo(repoUid: String) -> Observable<Results<TaskItem>> {
    let result = withRealm("tasksForLocalRepo") { realm -> Observable<Results<TaskItem>> in
      if let localRepo = realm.object(ofType: LocalRepository.self, forPrimaryKey: repoUid) {
        let tasks = localRepo.tasks
          .sorted(byKeyPath: "added", ascending: false)
        return Observable.collection(from: tasks)
      }
      return Observable.empty()
    }
    return result ?? .empty()
  }
  
  func tasksForAssignee(username: String) -> Observable<Results<TaskItem>> {
    print("------realmfile-------", RealmConfig.main.configuration.fileURL)
    let result = withRealm("tasksForAssignee") { realm -> Observable<Results<TaskItem>> in
      let assignees = realm.objects(Assignee.self)
      if let assignee = assignees.filter("name = '\(username)'").first {
        let tasks = assignee.tasks
          .sorted(byKeyPath: "added", ascending: false)
        return Observable.collection(from: tasks)
      }
      return .empty()
    }
    return result ?? .empty()
  }
  
  func localTasks() -> Observable<Results<TaskItem>> {
    let result = withRealm("openLocalTasks") { realm -> Observable<Results<TaskItem>> in
      let tasks = realm.objects(TaskItem.self)
        .filter("repository == nil")
        .sorted(byKeyPath: "added", ascending: false)
      
      return Observable.collection(from: tasks)
    }
    return result ?? .empty()
  }
  
  func subTasksForTask(task: TaskItem) -> Observable<Results<SubTask>> {
    let result = withRealm("subTasksForTask") { realm -> Observable<Results<SubTask>> in
      if let taskItem = realm.object(ofType: TaskItem.self, forPrimaryKey: task.uid) {
        let subTasks = taskItem.subTasks
          .sorted(byKeyPath: "added", ascending: false)
        return Observable.collection(from: subTasks)
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
  
  //read
  func getRecentLocal() -> Observable<TaskItem> {
    let result = withRealm("getRecentLocal") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        self.recentLocalDict.forEach({ (key, value) in
          observer.onNext(value)
        })
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  
  //read
  func getRecentServer() -> Observable<(TaskItem, TaskItemWithReference)> {
    let result = withRealm("getRecentServer") { realm in
      return Observable<(TaskItem, TaskItemWithReference)>.create({ observer -> Disposable in
        self.recentServerDict.forEach({ (key, value) in
          observer.onNext(value)
        })
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  func getNewServer() -> Observable<TaskItem> {
    let result = withRealm("getNewServer") { realm in
      return Observable<TaskItem>.create({ observer -> Disposable in
        self.newServerDict.forEach({ (key, value) in
          observer.onNext(value)
        })
        observer.onCompleted()
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  func seperateSequence(fetchedTasks: [TaskItem]) -> Completable {
    let result = withRealm("getOldLocal") { realm in
      return Completable.create(subscribe: { completable -> Disposable in
        for fetchedTask in fetchedTasks {
          if let localTask = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
            if localTask.updatedDate > fetchedTask.updatedDate {
              self.recentLocalDict.updateValue(localTask, forKey: fetchedTask.uid)
            } else if localTask.updatedDate < fetchedTask.updatedDate {
              let localRef = TaskItemReference(to: localTask)
              let tuple = TaskItemWithReference(localTask, localRef)
              self.recentServerDict.updateValue((fetchedTask, tuple), forKey: fetchedTask.uid)
            }
          } else {
            self.newServerDict.updateValue(fetchedTask, forKey: fetchedTask.uid)
          }
        }
        completable(.completed)
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  func localCreatedCount() -> Int {
    let realm = try! Realm(configuration: RealmConfig.main.configuration)
    let localCreatedTasks = realm.objects(TaskItem.self)
      .filter { !$0.isServerGeneratedType && $0.repository != nil }
    return localCreatedTasks.count
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
          if let changes = changes, let insertedIndex = changes.updated.first {
            let task = arr[insertedIndex]
            if !task.isServerGeneratedType && task.repository != nil {
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
  
  //write, newTask 는 아직 managed object 아니라서 thraedsafe 없이 넘겨줄 수 있음
  @discardableResult
  func deleteOldTask(oldTaskWithRef: TaskItemWithReference) -> Observable<TaskItem> {
    return Observable<TaskItem>.create({ [unowned self] (observer) -> Disposable in
      self.backgroundQueue.async {
        let realm = try! Realm(configuration: RealmConfig.main.configuration)
        if let exTask = realm.resolve(oldTaskWithRef.1) {
          try! realm.write {
            realm.delete(exTask)
          }
          print(Thread.current, "222write thread \(#function)")
          observer.onNext(exTask)
          print(Thread.current, "333write thread \(#function)")
        }
        observer.onCompleted()
      }
      return Disposables.create()
    })
  }
  
  func deleteTask(newTaskWithOldRef: (TaskItem, TaskItemWithReference)) -> Observable<TaskItem> {
    return Observable<TaskItem>.create({ [unowned self] (observer) -> Disposable in
      self.backgroundQueue.async {
        let realm = try! Realm(configuration: RealmConfig.main.configuration)
        if let exTask = realm.resolve(newTaskWithOldRef.1.1) {
          let newTask = newTaskWithOldRef.0
          
          try! realm.write {
            realm.delete(exTask)
          }
          print(Thread.current, "222write thread \(#function)")
          observer.onNext(newTask)
          print(Thread.current, "333write thread \(#function)")
        }
        observer.onCompleted()
      }
      return Disposables.create()
    })
  }
  
  func updateTask(newTaskWithOldRef: (TaskItem, TaskItemWithReference)) -> Observable<TaskItem> {
    return Observable<TaskItem>.create({ [unowned self] (observer) -> Disposable in
      self.backgroundQueue.async {
        let realm = try! Realm(configuration: RealmConfig.main.configuration)
        if let exTask = realm.resolve(newTaskWithOldRef.1.1) {
          let newTask = newTaskWithOldRef.0
          
          try! realm.write {
            for label in exTask.labels.toArray() {
              let tag = self.defaultTag(realm: realm, tagTitle: label.name)
              if let index = self.findIndex(tasks: tag.tasks.toArray(), exTask: exTask) {
                tag.tasks.remove(at: index)
              }
            }
            for user in exTask.assignees.toArray() {
              let assignee = self.defaultAssignee(realm: realm, assigneeName: user.name)
              if let index = self.findIndex(tasks: assignee.tasks.toArray(), exTask: exTask) {
                assignee.tasks.remove(at: index)
              }
            }
            exTask.title = newTask.title
            exTask.body = newTask.body
            exTask.checked = newTask.checked
            exTask.updated = newTask.updated
            exTask.owner = newTask.owner
            exTask.assignees = newTask.assignees
            exTask.labels = newTask.labels
            for label in exTask.labels.toArray() {
              let tag = self.defaultTag(realm: realm, tagTitle: label.name)
              tag.tasks.append(exTask)
            }
            for user in exTask.assignees.toArray() {
              let assignee = self.defaultAssignee(realm: realm, assigneeName: user.name)
              assignee.tasks.append(exTask)
            }
          }
          observer.onNext(exTask)
          print(Thread.current, "write thread \(#function)")
        }
        observer.onCompleted()
      }
      return Disposables.create()
    })
  }
  
  @discardableResult
  func addTask(newTaskWithOldRef: (TaskItem, TaskItemWithReference)) -> Observable<TaskItemWithReference> {
    return Observable<TaskItemWithReference>.create({ [unowned self] (observer) -> Disposable in
      self.backgroundQueue.async {
        let realm = try! Realm(configuration: RealmConfig.main.configuration)
        if let exTask = realm.resolve(newTaskWithOldRef.1.1) {
          let newTask = newTaskWithOldRef.0
          newTask.repository = exTask.repository
          newTask.tag = exTask.tag
          newTask.assignee = exTask.assignee
          newTask.subTasks = exTask.subTasks
          newTask.localRepository = exTask.localRepository
          try! realm.write {
            realm.add(newTask)
            let localRepo = self.defaultLocalRepo(realm: realm,
                                                  repoUid: newTask.repository!.uid,
                                                  repoName: newTask.repository!.name)
            localRepo.tasks.append(newTask)
            for label in newTask.labels.toArray() {
              let tag = self.defaultTag(realm: realm, tagTitle: label.name)
              tag.tasks.append(newTask)
            }
            for user in newTask.assignees.toArray() {
              let assignee = self.defaultAssignee(realm: realm, assigneeName: user.name)
              assignee.tasks.append(newTask)
            }
          }
          let ref = TaskItemReference(to: exTask)
          observer.onNext((exTask, ref))
        }
        
        observer.onCompleted()
        print(Thread.current, "write thread \(#function)")
      }
      return Disposables.create()
    })
  }
  
  @discardableResult
  func deleteTaskOnMain(localTask: TaskItem) -> Observable<Void> {
    let result = withRealm("deleteTaskOnMain") { realm in
      return Observable<Void>.create({ observer -> Disposable in
        if let task = realm.object(ofType: TaskItem.self, forPrimaryKey: localTask.uid) {
          print("task--------", task)
          try! realm.write {
            realm.delete(task)
            print(Thread.current, "write thread \(#function)")
          }
          observer.onNext(())
        }
        observer.onCompleted()
        
        return Disposables.create()
      })
    }
    return result ?? .empty()
  }
  
  //write
  @discardableResult
  func add(newTask: TaskItem) -> Observable<TaskItem> {
    return Observable<TaskItem>.create({ [unowned self] (observer) -> Disposable in
      self.backgroundQueue.async {
        let realm = try! Realm(configuration: RealmConfig.main.configuration)
        try! realm.write {
          realm.add(newTask)
          let localRepo = self.defaultLocalRepo(realm: realm,
                                                repoUid: newTask.repository!.uid,
                                                repoName: newTask.repository!.name)
          localRepo.tasks.append(newTask)
          for label in newTask.labels.toArray() {
            let tag = self.defaultTag(realm: realm, tagTitle: label.name)
            tag.tasks.append(newTask)
          }
          for user in newTask.assignees.toArray() {
            let assignee = self.defaultAssignee(realm: realm, assigneeName: user.name)
            assignee.tasks.append(newTask)
          }
          
        }
        observer.onNext(newTask)
        print(Thread.current, "write thread \(#function)")
      }
      observer.onCompleted()
      return Disposables.create()
    })
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
  
  func defaultAssignee(realm: Realm, assigneeName: String) -> Assignee {
    if let assignee = realm.object(ofType: Assignee.self, forPrimaryKey: assigneeName) {
      return assignee
    }
    let newAssignee = Assignee(name: assigneeName)
    realm.add(newAssignee)
    return realm.object(ofType: Assignee.self, forPrimaryKey: assigneeName)!
  }
  
  func defaultLocalRepo(realm: Realm, repoUid: String, repoName: String) -> LocalRepository {
    if let repo = realm.object(ofType: LocalRepository.self, forPrimaryKey: repoUid) {
      return repo
    }
    let newRepo = LocalRepository(uid: repoUid, name: repoName)
    realm.add(newRepo)
    return realm.object(ofType: LocalRepository.self, forPrimaryKey: repoUid)!
  }
  
  static func migrate(_ migration: Migration, fileSchemaVersion: UInt64) {
    if fileSchemaVersion == 1 {
      migration.enumerateObjects(ofType: TaskItem.className()) { (oldObject, newObject) in
        if let oldObject = oldObject, let newObject = newObject {
          if oldObject["repository"] != nil {
            let updated = oldObject["updated"] as! String
            let oldDate = updated.convertToDate()!
            let newUpdated = oldDate.converToPastDateString()
            newObject["updated"] = newUpdated
          }
        }
      }
    }
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
