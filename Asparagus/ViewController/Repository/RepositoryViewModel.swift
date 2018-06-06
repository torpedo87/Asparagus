//
//  RepositoryViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 5. 31..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct RepositoryViewModel {
  private let bag = DisposeBag()
  private let authService: AuthServiceRepresentable
  private let issueService: IssueServiceRepresentable
  private let syncService: SyncServiceRepresentable
  private let sceneCoordinator: SceneCoordinatorType
  private let localTaskService: LocalTaskService
  
  
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
    let globalScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
    
    Observable.combineLatest(Reachability.rx.isOnline,
                             authService.loginStatus.asObservable())
      .filter { $0.0 && $0.1 }
      .subscribeOn(globalScheduler)
      .subscribe(onNext: { _ in
        syncService.syncStart(fetchedTasks: issueService.fetchAllIssues(page: 1))
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
    
    bindOutput()
  }
  
  func bindOutput() {
    let syncRunning = syncService.running.share()
    
    syncRunning.asObservable()
      .observeOn(MainScheduler.instance)
      .filter{ return !$0 }
      .skip(1)
      .subscribe(onNext: { _ in
        self.syncService.realTimeSync()
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
  
  func onAuthTask(isLoggedIn: Bool) -> Action<(String, String), AuthService.AccountStatus> {
    return Action { tuple in
      if isLoggedIn {
        return self.authService.removeToken(userId: tuple.0, userPassword: tuple.1)
      } else {
        return self.authService.requestToken(userId: tuple.0, userPassword: tuple.1)
      }
    }
  }
  
  
  func onSync() -> CocoaAction {
    return CocoaAction {
      let isLoggedIn = UserDefaults.loadToken() != nil
      let syncViewModel = SyncViewModel(authService: self.authService,
                                        coordinator: self.sceneCoordinator,
                                        authAction: self.onAuthTask(isLoggedIn: isLoggedIn))
      return self.sceneCoordinator.transition(to: .sync(syncViewModel), type: .modal)
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
                                     authService: this.authService)
      
      return this.sceneCoordinator
        .transition(to: .issue(viewModel), type: .push)
        .asObservable()
    }
  }(self)
}
