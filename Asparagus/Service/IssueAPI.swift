//
//  IssueAPI.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import Moya

enum IssueAPI {
  
  case fetchAllIssues(page: Int)
  case createIssue(title: String, body: String, repo: Repository)
  case editIssue(newTitle: String, newBody: String, newState: String, newLabels: [String], newAssignees: [String], exTask: TaskItem)
  case createIssueWithLocalTask(localTaskWithRef: LocalTaskService.TaskItemWithReference)
  case getRepoUsers(repo: Repository)
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
    case .editIssue(_, _, _, _, _, let exTask):
      return "/repos/\(exTask.repository!.owner!.name)/\(exTask.repository!.name)/issues/\(exTask.number)"
    case .createIssue(_, _, let repo):
      return "/repos/\(repo.owner!.name)/\(repo.name)/issues"
    case .createIssueWithLocalTask(let tuple):
      return "/repos/\(tuple.0.repository!.owner!.name)/\(tuple.0.repository!.name)/issues"
    case .getRepoUsers(let repo):
      return "/repos/\(repo.owner!.name)/\(repo.name)/assignees"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .fetchAllIssues, .getRepoUsers:
      return .get
    case .editIssue:
      return .patch
    case .createIssue, .createIssueWithLocalTask:
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
    case .editIssue(let newTitle, let newBody, let newState, let newLabels, let newAssignees, _):
      return .requestParameters(parameters: ["body": newBody,
                                             "title": newTitle,
                                             "state": newState,
                                             "labels": newLabels,
                                             "assignees": newAssignees],
                                encoding: JSONEncoding.default)
    case let .createIssue(title, body, _):
      return .requestParameters(parameters: ["body": body,
                                             "title": title],
                                encoding: JSONEncoding.default)
    case let .createIssueWithLocalTask(tuple):
      return .requestParameters(parameters: ["body": tuple.0.body ?? "",
                                             "title": tuple.0.title,
                                             "labels": tuple.0.labels.toArray().map{ $0.name },
                                             "assignees": tuple.0.assignees.toArray().map{ $0.name }],
                                encoding: JSONEncoding.default)
    case .getRepoUsers(_):
      return .requestPlain
    }
  }
  
}
