//
//  IssueFetcher.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class IssueFetcher {
  let issueService: IssueServiceRepresentable
  let taskService: TaskServiceType
  
  //output
  let issues: Observable<[TaskItem]>
  
  init(account: Driver<AuthService.AccountStatus>,
       issueService: IssueServiceRepresentable,
       taskService: TaskServiceType) {
    self.issueService = issueService
    self.taskService = taskService
    
    let currentAccount: Observable<Token> = account
      .filter { account in
        switch account {
        case .authorized: return true
        default: return false
        }
      }
      .map { account -> Token in
        switch account {
        case .authorized(let token):
          return token!
        default: fatalError()
        }
      }
      .asObservable()
    
    let reachableWithAccount = Observable.combineLatest(
      Reachability.rx.status,
      currentAccount,
      resultSelector: { status, account in
        return status == .online ? account : nil
    })
      .filter { $0 != nil }
      .map { $0! }
    
    issues = reachableWithAccount
      .flatMap({ (token) -> Observable<[TaskItem]> in
        if token != nil {
          return issueService.fetchAllIssues(page: 1)
        }
        return Observable.empty()
      })
      .share(replay: 1, scope: .whileConnected)
    
  }
}
