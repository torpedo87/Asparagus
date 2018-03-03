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
  @objc dynamic var added = ""
  @objc dynamic var updated = ""
  
  override static func primaryKey() -> String? {
    return "uid"
  }
  
  enum CodingKeys: String, CodingKey {
    case uid = "id"
    case title
    case body
    case checked = "state"
    case added = "created_at"
    case updated = "updated_at"
  }
  
  convenience init(uid: Int, title: String, body: String?, checked: String, added: String, updated: String) {
    self.init()
    self.uid = uid
    self.title = title
    self.body = body
    self.checked = checked
    self.added = added
    self.updated = updated
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let uid = try container.decode(Int.self, forKey: .uid)
    let title = try container.decode(String.self, forKey: .title)
    let body = try container.decode(String?.self, forKey: .body)
    let checked = try container.decode(String.self, forKey: .checked)
    let added = try container.decode(String.self, forKey: .added)
    let updated = try container.decode(String.self, forKey: .updated)
    self.init(uid: uid, title: title, body: body, checked: checked, added: added, updated: updated)
  }
}

extension TaskItem {
  func setDateWhenCreated() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    let now = dateFormatter.string(from: Date())
    self.added = now
    self.updated = now
  }
  
  func setDateWhenUpdated() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    let now = dateFormatter.string(from: Date())
    self.updated = now
  }
  
  func getUpdatedDate() -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return dateFormatter.date(from: self.updated)!
  }
}
