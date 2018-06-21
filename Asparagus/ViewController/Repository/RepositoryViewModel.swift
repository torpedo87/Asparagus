//
//  RepositoryViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 5. 31..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct RepositoryViewModel {
  private let bag = DisposeBag()
  private let authService: AuthServiceRepresentable
  private let issueService: IssueServiceRepresentable
  private let syncService: SyncServiceRepresentable
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskService
  private let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
  
  init(authService: AuthServiceRepresentable,
       syncService: SyncServiceRepresentable,
       issueService: IssueServiceRepresentable,
       coordinator: SceneCoordinatorType,
       localTaskService: LocalTaskService) {
    self.authService = authService
    self.sceneCoordinator = coordinator
    self.localTaskService = localTaskService
    self.issueService = issueService
    self.syncService = syncService
    
    Observable.combineLatest(Reachability.rx.isOnline,
                             authService.loginStatus.asObservable())
      .filter { $0.0 && $0.1 }
      .flatMap { _ -> Observable<User> in
        return authService.getUser()
      }
      .map({ user -> Bool in
        UserDefaults.saveMe(me: user)
        return true
      })
      .subscribe()
      .disposed(by: bag)
    
    //온라인 및 로그인상태시 이슈 가져오기
    Observable.combineLatest(Reachability.rx.isOnline,
                             authService.loginStatus.asObservable())
      .filter { $0.0 && $0.1 }
      .subscribeOn(globalScheduler)
      .subscribe(onNext: { _ in
        syncService.syncStart()
      })
      .disposed(by: bag)
    
    localTaskService.tasksForLocalRepo(repoUid: "Today")
      .map { results -> Int in
        return results.count
      }.asDriver(onErrorJustReturn: 0)
      .drive(onNext: { counts in
        UIApplication.shared.applicationIconBadgeNumber = counts
      })
      .disposed(by: bag)
    
    syncService.running.asObservable()
      .observeOn(MainScheduler.instance)
      .filter{ return !$0 }
      .skip(1)
      .subscribe(onNext: { _ in
        syncService.realTimeSync()
      })
      .disposed(by: bag)
  }
  
  func isRunning() -> Observable<Bool> {
    return syncService.running.asObservable()
  }
  
  func isLoggedIn() -> Observable<Bool> {
    return authService.loginStatus.asObservable()
  }
  
  func localRepositories() -> Observable<[LocalRepository]> {
    return localTaskService.localRepositories()
      .map { (localRepoResults) -> [LocalRepository] in
        let today = localRepoResults
          .filter("uid = 'Today'")
          .toArray()
        
        let localRepoItems = localRepoResults
          .filter("uid != 'Today'")
          .sorted(byKeyPath: "name", ascending: true)
          .toArray()
        
        return today + localRepoItems
    }
  }
  
  func onSync() -> CocoaAction {
    return CocoaAction {
      let syncViewModel = SyncViewModel(authService: self.authService,
                                        coordinator: self.sceneCoordinator)
      return self.sceneCoordinator.transition(to: .sync(syncViewModel), type: .popover)
        .asObservable()
        .map{ _ in }
    }
  }
  
  lazy var issueAction: Action<LocalRepository, Swift.Never> = { this in
    return Action { repo in
      let viewModel = IssueViewModel(selectedRepo: repo,
                                     issueService: this.issueService,
                                     coordinator: this.sceneCoordinator,
                                     localTaskService: this.localTaskService,
                                     authService: this.authService,
                                     syncService: this.syncService)
      
      return this.sceneCoordinator
        .transition(to: .issue(viewModel), type: .push)
        .asObservable()
    }
  }(self)
}
