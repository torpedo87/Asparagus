//
//  SubTask.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 22..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift
import RxDataSources

class SubTask: Object {
  @objc dynamic var uid = ""
  @objc dynamic var title = ""
  @objc dynamic var checked = ""
  @objc dynamic var added = ""
  let superTask = LinkingObjects(fromType: TaskItem.self, property: "subTasks")
  
  override static func primaryKey() -> String? {
    return "uid"
  }
  
  convenience init(uid: String = UUID().uuidString, title: String, checked: String, added: String) {
    self.init()
    self.uid = uid
    self.title = title
    self.checked = checked
    self.added = added
  }
  
  func setDateWhenCreated() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    let now = dateFormatter.string(from: Date())
    self.added = now
  }
}

extension SubTask: IdentifiableType {
  var identity: String {
    return self.isInvalidated ? "" : uid
  }
}
