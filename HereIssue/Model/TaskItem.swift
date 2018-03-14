//
//  TaskItem.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class TaskItem: Object, Decodable {
  @objc dynamic var uid = ""
  @objc dynamic var title = ""
  @objc dynamic var body: String? = nil
  @objc dynamic var checked = ""
  @objc dynamic var added = ""
  @objc dynamic var updated = ""
  @objc dynamic var owner: User?
  @objc dynamic var repository: Repository?
  @objc dynamic var number = 0
  
  // local only properties
  var updatedDate: Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter.date(from: self.updated)!
  }
  
  var isServerGeneratedType: Bool {
    return uid.count != UUID().uuidString.count
  }
  
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
    case owner = "user"
    case repository
    case number
  }
  
  convenience init(uid: String = UUID().uuidString, title: String, body: String?, checked: String, added: String, updated: String, owner: User?, repository: Repository?, number: Int) {
    self.init()
    self.uid = uid
    self.title = title
    self.body = body
    self.checked = checked
    self.added = added
    self.updated = updated
    self.owner = owner
    self.repository = repository
    self.number = number
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let intId = try container.decode(Int.self, forKey: .uid)
    let uid = "\(intId)"
    let title = try container.decode(String.self, forKey: .title)
    let body = try container.decodeIfPresent(String.self, forKey: .body)
    let checked = try container.decode(String.self, forKey: .checked)
    let added = try container.decode(String.self, forKey: .added)
    let updated = try container.decode(String.self, forKey: .updated)
    let owner = try container.decode(User.self, forKey: .owner)
    let repository = try container.decodeIfPresent(Repository.self, forKey: .repository)
    let number = try container.decode(Int.self, forKey: .number)
    self.init(uid: uid, title: title, body: body, checked: checked, added: added, updated: updated, owner: owner, repository: repository, number: number)
  }
}

extension TaskItem: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(Int(uid), forKey: .uid)
    try container.encode(title, forKey: .title)
    try container.encodeIfPresent(body, forKey: .body)
    try container.encode(checked, forKey: .checked)
    try container.encode(added, forKey: .added)
    try container.encodeIfPresent(owner, forKey: .owner)
    try container.encodeIfPresent(repository, forKey: .repository)
    try container.encode(number, forKey: .number)
  }
}

extension TaskItem {
  func setDateWhenCreated() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    //let nowDate = Date(timeInterval: -9 * 60 * 60, since: Date())
    let now = dateFormatter.string(from: Date())
    self.added = now
    self.updated = now
  }
  
  func setDateWhenUpdated() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    //let nowDate = Date(timeInterval: -9 * 60 * 60, since: Date())
    let now = dateFormatter.string(from: Date())
    self.updated = now
  }
  
  func getUpdatedDate() -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter.date(from: self.updated)
  }
}
