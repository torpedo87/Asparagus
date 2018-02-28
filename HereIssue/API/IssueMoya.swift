//
//  IssueMoya.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import Moya

enum IssueMoya {
  
  case fetchAllIssues(page: Int)
}

extension IssueMoya: TargetType {
  
  //for test
  var sampleData: Data {
    return Data()
  }
  
  var headers: [String : String]? {
    guard let token = UserDefaults.loadToken()?.token else { fatalError() }
    return [
      "Content-type": "application/json; charset=utf-8",
      "Authorization": "Bearer \(token)"
    ]
  }
  
  var baseURL: URL { return URL(string: "https://api.github.com")! }
  
  var path: String {
    switch self {
    case .fetchAllIssues(_):
      return "/issues"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .fetchAllIssues:
      return .get
    }
  }
  
  var task: Task {
    switch self {
      
    case let .fetchAllIssues(page):
      return .requestParameters(parameters: ["sort": "created",
                                             "state": "all",
                                             "filter": "all",
                                             "page": "\(page)"],
                                encoding: URLEncoding.queryString)
    }
  }
  
}
