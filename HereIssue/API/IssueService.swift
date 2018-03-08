//
//  IssueService.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya

//시퀀스를 발생

protocol IssueServiceRepresentable {
  func fetchAllIssues(page: Int) -> Observable<[TaskItem]>
  @discardableResult
  func editServerTask(newTitle: String, newBody: String, newState: String, exTask: TaskItem) -> Observable<TaskItem>
  func createIssue(title: String, body: String, repo: Repository) -> Observable<TaskItem>
}
class IssueService: IssueServiceRepresentable {
  
  enum Errors: Error {
    case fetchAllIssuesFailed
    case editServerTaskFailed
    case pagingFailed
    case createIssueFailed
  }
  
  private let bag = DisposeBag()
  var provider: MoyaProvider<IssueAPI>!
  
  init(provider: MoyaProvider<IssueAPI> = MoyaProvider<IssueAPI>()) {
    self.provider = provider
  }
  
  func fetchAllIssues(page: Int) -> Observable<[TaskItem]> {
    return paging()
      .flatMap { [unowned self] in
        self.provider.rx.request(.fetchAllIssues(page: $0))
      }
      .reduce([TaskItem](), accumulator: { items, response in
        let decoded = try! JSONDecoder().decode([TaskItem].self, from: response.data)
        return items + decoded
      })
  }
  
  private func paging() -> Observable<Int> {
    return Observable.create { observer in
      self.provider.request(.fetchAllIssues(page: 1))
      { result in
        var lastPage = Int()
        if let link = result.value?.response?.allHeaderFields["Link"] as? String {
          lastPage = (self.getLastPageFromLinkHeader(link: link))
        }
        switch result {
        case .success(let response):
          if 200 ..< 300 ~= response.statusCode {
            for page in 1...lastPage {
              observer.onNext(page)
            }
            observer.onCompleted()
          } else {
            observer.onError(Errors.pagingFailed)
          }
        case .failure(let error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }
  
  func editServerTask(newTitle: String, newBody: String, newState: String, exTask: TaskItem) -> Observable<TaskItem> {
    return Observable.create({ (observer) -> Disposable in
      self.provider.request(.editIssue(newTitle: newTitle,
                                       newBody: newBody,
                                       newState: newState,
                                       exTask: exTask))
      { (result) in
        switch result {
        case let .success(moyaResponse):
          let data = moyaResponse.data
          let statusCode = moyaResponse.statusCode
          if 200 ..< 300 ~= statusCode {
            let newTask = try! JSONDecoder().decode(TaskItem.self, from: data)
            observer.onNext(newTask)
          } else {
            observer.onError(Errors.editServerTaskFailed)
          }
        case let .failure(error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    })
    
  }
  
  func createIssue(title: String, body: String, repo: Repository) -> Observable<TaskItem> {
    return Observable.create({ (observer) -> Disposable in
      self.provider.request(.createIssue(title: title,
                                         body: body,
                                         repo: repo)) { (result) in
      switch result {
      case let .success(moyaResponse):
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode
        if 200 ..< 300 ~= statusCode {
          let newIssue = try! JSONDecoder().decode(TaskItem.self, from: data)
          observer.onNext(newIssue)
        } else {
          observer.onError(Errors.createIssueFailed)
        }
      case let .failure(error):
        observer.onError(error)
      }
      }
      return Disposables.create()
    })
    
  }
  
  //helper
  func getLastPageFromLinkHeader(link: String) -> Int {
    let temp = link.components(separatedBy: "=")[7]
    let lastPage = Int((temp.components(separatedBy: "&")[0]))!
    return lastPage
  }
}
