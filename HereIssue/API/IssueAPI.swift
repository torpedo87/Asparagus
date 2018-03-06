//
//  IssueAPI.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import Moya

enum IssueAPI {
  
  case fetchAllIssues(page: Int)
  case createIssue(title: String, body: String, repo: Repository)
  case editIssue(newTitle: String, newBody: String, newState: String, exTask: TaskItem)
}

extension IssueAPI: TargetType {
  
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
    case .editIssue(_, _, _, let exTask):
      return "/repos/\(exTask.owner!.name)/\(exTask.repository!.name)/issues/\(exTask.number)"
    case .createIssue(_, _, let repo):
      return "/repos/\(repo.owner!.name)/\(repo.name)/issues"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .fetchAllIssues:
      return .get
    case .editIssue:
      return .patch
    case .createIssue:
      return .post
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
    case .editIssue(let newTitle, let newBody, let newState, _):
      return .requestParameters(parameters: ["body": newBody,
                                             "title": newTitle,
                                             "state": newState],
                                encoding: JSONEncoding.default)
    case let .createIssue(title, body, _):
      return .requestParameters(parameters: ["body": body,
                                             "title": title],
                                encoding: JSONEncoding.default)
    }
  }
  
}
