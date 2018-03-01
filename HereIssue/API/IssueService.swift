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

protocol IssueServiceRepresentable {
  func fetchAllIssues(page: Int) -> Observable<[TaskItem]>
}
class IssueService: IssueServiceRepresentable {
  
  enum Errors: Error {
    case requestFailed
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
            observer.onError(Errors.requestFailed)
          }
        case .failure(let error):
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }
  
  //helper
  func getLastPageFromLinkHeader(link: String) -> Int {
    let temp = link.components(separatedBy: "=")[7]
    let lastPage = Int((temp.components(separatedBy: "&")[0]))!
    return lastPage
  }
}
