//
//  TaskItem.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class TaskItem: Object, Codable {
  @objc dynamic var uid = 0
  @objc dynamic var title = ""
  @objc dynamic var body: String? = nil
  @objc dynamic var checked = ""
  
  override static func primaryKey() -> String? {
    return "uid"
  }
  
  enum CodingKeys: String, CodingKey {
    case uid = "id"
    case title
    case body
    case checked = "state"
  }
  
  convenience init(uid: Int, title: String, body: String?, checked: String) {
    self.init()
    self.uid = uid
    self.title = title
    self.body = body
    self.checked = checked
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let uid = try container.decode(Int.self, forKey: .uid)
    let title = try container.decode(String.self, forKey: .title)
    let body = try container.decode(String?.self, forKey: .body)
    let checked = try container.decode(String.self, forKey: .checked)
    self.init(uid: uid, title: title, body: body, checked: checked)
  }
}
