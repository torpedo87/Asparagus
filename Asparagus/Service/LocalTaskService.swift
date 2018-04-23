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
  var recentServerDict: [String:LocalTaskService.TaskItemWithReference] { get }
  var recentLocalDict: [String:TaskItem] { get }
  var newServerDict: [String:TaskItem] { get }
  @discardableResult
  func createBlankTask(title: String) -> Observable<TaskItem>
  @discardableResult
  func createSubTask(title: String, superTask: TaskItem) -> Observable<SubTask>
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String) -> Observable<TaskItem>
  func updateRepo(taskWithRef: LocalTaskService.TaskItemWithReference, repo: Repository?) -> Observable<TaskItem>
  func updateTag(taskWithRef: LocalTaskService.TaskItemWithReference, tag: Tag, mode: LocalTaskService.EditMode) -> Observable<TaskItem>
  func updateAssignee(taskWithRef: LocalTaskService.TaskItemWithReference, assignee: Assignee, mode: LocalTaskService.EditMode) -> Observable<TaskItem>
  @discardableResult
  func toggle(task: TaskItem) -> Observable<TaskItem>
  func toggle(task: SubTask) -> Observable<SubTask>
  func repositories() -> Observable<Results<Repository>>
  func getRecentLocal() -> Observable<TaskItem>
  func getRecentServer() -> Observable<LocalTaskService.TaskItemWithReference>
  func getNewServer() -> Observable<TaskItem>
  func seperateSequence(fetchedTasks: [TaskItem]) -> Completable
  func getLocalCreated() -> Observable<LocalTaskService.TaskItemWithReference>
  func deleteTask(newTaskWithOldRef: LocalTaskService.TaskItemWithReference) -> Observable<TaskItem>
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
  //func updateTask(newTaskWithOldRef: LocalTaskService.TaskItemWithReference) -> Observable<TaskItem>
}

class LocalTaskService: LocalTaskServiceType {
  typealias TaskItemReference = ThreadSafeReference<TaskItem>
  typealias TaskItemWithReference = (TaskItem, TaskItemReference)
  var recentServerDict = [String:TaskItemWithReference]()
  var recentLocalDict = [String:TaskItem]()
  var newServerDict = [String:TaskItem]()
  
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
      if let managedTask = realm.object(ofType: TaskItem.self, forPrimaryKey: task.uid) {
        return .just(managedTask)
      }
      return .empty()
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
      if let managedTask = realm.object(ofType: SubTask.self, forPrimaryKey: subTask.uid) {
        return .just(managedTask)
      }
      return .empty()
    }
    return result ?? .empty()
  }
  
  //title, body 수정
  @discardableResult
  func updateTitleBody(exTask: TaskItem, newTitle: String, newBody: String) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      realm.writeAsync(obj: exTask, block: { (realm, exTask) in
        if let exTask = exTask {
          exTask.title = newTitle
          exTask.body = newBody
          exTask.setDateWhenUpdated()
        }
        print(Thread.current, "write thread \(#function)")
      })
      return .just(exTask)
    }
    return result ?? .error(TaskServiceError.updateFailed(exTask))
  }
  
  @discardableResult
  func updateRepo(taskWithRef: TaskItemWithReference, repo: Repository? = nil) -> Observable<TaskItem> {
    let result = withRealm("updateRepo") { realm -> Observable<TaskItem> in
      var repoName = ""
      if let repo = repo {
        repoName = repo.name
      }
      if let exTask = realm.resolve(taskWithRef.1) {
        realm.writeAsync(obj: exTask, block: { (realm, exTask) in
          if let exTask = exTask {
            exTask.setDateWhenUpdated()
            exTask.repository = self.getRepository(repoName: repoName)
          }
          print(Thread.current, "write thread \(#function)")
        })
        return .just(exTask)
      }
      return .empty()
    }
    return result ?? .empty()
  }
  
  enum EditMode {
    case add
    case delete
  }
  
  func updateTag(taskWithRef: TaskItemWithReference, tag: Tag, mode: EditMode) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      //파라미터의 tag는 Ref 없어서 thread 이동 불가
      let tagTitle = tag.title
      if let exTask = realm.resolve(taskWithRef.1) {
        realm.writeAsync(obj: exTask, block: { (realm, exTask) in
          if let exTask = exTask {
            let group = self.defaultTag(realm: realm, tagTitle: tagTitle)
            switch mode {
            case .add: do {
              group.tasks.append(exTask)
              exTask.labels.append(Label(name: tagTitle))
              }
            case .delete: do {
              if let i = self.findIndex(tasks: group.tasks.toArray(), exTask: exTask) {
                group.tasks.remove(at: i)
              }
              
              if let j = self.findIndex(labels: exTask.labels.toArray(), exTagTitle: tagTitle) {
                exTask.labels.remove(at: j)
              }
              
              }
            }
            exTask.setDateWhenUpdated()
          }
          print(Thread.current, "write thread \(#function)")
        })
        return .just(exTask)
      }
      return .empty()
    }
    return result ?? .empty()
  }
  
  func updateAssignee(taskWithRef: TaskItemWithReference, assignee: Assignee, mode: EditMode) -> Observable<TaskItem> {
    let result = withRealm("updating title") { realm -> Observable<TaskItem> in
      let assigneeName = assignee.name
      if let exTask = realm.resolve(taskWithRef.1) {
        realm.writeAsync(obj: exTask, block: { (realm, exTask) in
          if let exTask = exTask {
            let group = self.defaultAssignee(realm: realm, assigneeName: assigneeName)
            switch mode {
            case .add: do {
              group.tasks.append(exTask)
              exTask.assignees.append(User(name: assigneeName))
              }
            case .delete: do {
              if let i = self.findIndex(tasks: group.tasks.toArray(), exTask: exTask) {
                group.tasks.remove(at: i)
              }
              
              if let j = self.findIndex(assignees: exTask.assignees.toArray(), username: assigneeName) {
                exTask.assignees.remove(at: j)
              }
              
              }
            }
            exTask.setDateWhenUpdated()
          }
          print(Thread.current, "write thread \(#function)")
        })
        return .just(exTask)
      }
      return .empty()
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
  
  @discardableResult
  func toggle(task: SubTask) -> Observable<SubTask> {
    let result = withRealm("toggling") { realm -> Observable<SubTask> in
      realm.writeAsync(obj: task, block: { (realm, task) in
        if task?.checked == "open" {
          task?.checked = "closed"
        } else {
          task?.checked = "open"
        }
        print(Thread.current, "write thread \(#function)")
      })
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
          .filter("checked = 'open'")
          .sorted(byKeyPath: "added", ascending: false)
        return Observable.collection(from: tasks)
      }
      return Observable.empty()
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
  
  //로컬이 최신인 것만 필터링
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
  
  func getRecentServer() -> Observable<TaskItemWithReference> {
    let result = withRealm("getRecentServer") { realm in
      return Observable<TaskItemWithReference>.create({ observer -> Disposable in
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
        fetchedTasks.forEach { fetchedTask in
          if let localTask = realm.object(ofType: TaskItem.self, forPrimaryKey: fetchedTask.uid) {
            if localTask.updatedDate > fetchedTask.updatedDate {
              self.recentLocalDict.updateValue(localTask, forKey: fetchedTask.uid)
            } else if localTask.updatedDate < fetchedTask.updatedDate {
              let localRef = TaskItemReference(to: localTask)
              print("-------------recent-------", fetchedTask.title)
              self.recentServerDict.updateValue((fetchedTask, localRef), forKey: fetchedTask.uid)
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
  
  @discardableResult
  func deleteTask(newTaskWithOldRef: TaskItemWithReference) -> Observable<TaskItem> {
    let result = withRealm("deleteTask") { realm -> Observable<TaskItem> in
      if let exTask = realm.resolve(newTaskWithOldRef.1) {
        try realm.write {
          //라벨
          exTask.labels.forEach {
            let tag = self.defaultTag(realm: realm, tagTitle: $0.name)
            if let i = self.findIndex(tasks: tag.tasks.toArray(), exTask: exTask) {
              tag.tasks.remove(at: i)
            }
            
          }
          //repo
          let localRepo = self.defaultLocalRepo(realm: realm,
                                                repoUid: exTask.repository!.uid,
                                                repoName: exTask.repository!.name)
          if let i = self.findIndex(tasks: localRepo.tasks.toArray(), exTask: exTask) {
            localRepo.tasks.remove(at: i)
          }
          
          //assignee
          exTask.assignees.forEach {
            let assignee = self.defaultAssignee(realm: realm, assigneeName: $0.name)
            if let i = self.findIndex(tasks: assignee.tasks.toArray(), exTask: exTask) {
              assignee.tasks.remove(at: i)
            }
          }
          realm.delete(exTask)
        }
      }
      return .just(newTaskWithOldRef.0)
    }
    return result ?? .empty()
  }
  
//  func updateTask(newTaskWithOldRef: TaskItemWithReference) -> Observable<TaskItem> {
//    let result = withRealm("deleteTask") { realm in
//      return Observable<TaskItem>.create({ observer -> Disposable in
//        if let exTask = realm.resolve(newTaskWithOldRef.1) {
//          realm.writeAsync(obj: exTask, block: { (realm, exTask) in
//            if let exTask = exTask {
//              let newTask = newTaskWithOldRef.0
//              //라벨
//              let exLabelSet = Set(exTask.labels)
//              let newLabelSet = Set(newTask.labels)
//              let intersect = exLabelSet.intersection(newLabelSet)
//              let deletedLabels = exLabelSet.subtracting(intersect)
//              let newLabels = newLabelSet.subtracting(intersect)
//              //새로 추가된 라벨
//              newLabels.forEach {
//                let tag = self.defaultTag(realm: realm, tagTitle: $0.name)
//                tag.tasks.append(newTask)
//              }
//              //삭제된 라벨
//              deletedLabels.forEach {
//                let tag = self.defaultTag(realm: realm, tagTitle: $0.name)
//                if let i = self.findIndex(tasks: tag.tasks.toArray(), exTask: exTask) {
//                  tag.tasks.remove(at: i)
//                }
//
//              }
//
//              //assignee
//              let exAssigneeSet = Set(exTask.assignees)
//              let newAssigneeSet = Set(newTask.assignees)
//              let intersectAssignee = exAssigneeSet.intersection(newAssigneeSet)
//              let deletedAssignees = exAssigneeSet.subtracting(intersectAssignee)
//              let newAssignees = newAssigneeSet.subtracting(intersectAssignee)
//
//              //새로 추가된 assignee
//              newAssignees.forEach {
//                let assignee = self.defaultAssignee(realm: realm, assigneeName: $0.name)
//                print("------newAssignee----, \($0.name)")
//                assignee.tasks.append(newTask)
//              }
//              //삭제된 assignee
//              deletedAssignees.forEach {
//                let assignee = self.defaultAssignee(realm: realm, assigneeName: $0.name)
//                if let i = self.findIndex(tasks: assignee.tasks.toArray(), exTask: exTask) {
//                  assignee.tasks.remove(at: i)
//                }
//              }
//
//              exTask.title = newTask.title
//              exTask.body = newTask.body
//              exTask.labels = newTask.labels
//              exTask.assignees = newTask.assignees
//              print(Thread.current, "write thread \(#function)")
//            }
//          })
//          observer.onNext(newTaskWithOldRef.0)
//        }
//        observer.onCompleted()
//        return Disposables.create()
//      })
//    }
//    return result ?? .empty()
//  }
  
  @discardableResult
  func add(newTask: TaskItem) -> Observable<TaskItem> {
    let result = withRealm("add") { realm -> Observable<TaskItem> in
      try realm.write {
        let localRepo = self.defaultLocalRepo(realm: realm,
                                              repoUid: newTask.repository!.uid,
                                              repoName: newTask.repository!.name)
        localRepo.tasks.append(newTask)
        newTask.labels.forEach {
          let tag = self.defaultTag(realm: realm, tagTitle: $0.name)
          tag.tasks.append(newTask)
        }
        newTask.assignees.forEach {
          let assignee = self.defaultAssignee(realm: realm, assigneeName: $0.name)
          assignee.tasks.append(newTask)
        }
        print(Thread.current, "write thread \(#function)")
      }
      return .just(newTask)
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
      migration.enumerateObjects(ofType: "Tag") { (oldObject, newObject) in
        if let newObject = newObject {
          if let tasks = newObject["tasks"] as? List<TaskItem> {
            tasks.forEach{ $0.labels.append(Label(name: newObject["title"] as! String)) }
          }
        }
      }
      migration.enumerateObjects(ofType: "TaskItem") { (oldObject, newObject) in
        if let newObject = newObject {
          if let repository = newObject["repository"] as? Repository {
            let localRepo = LocalRepository(uid: repository.uid, name: repository.name)
            
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
