//
//  Tag.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 14..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class Tag: Object {
  @objc dynamic var title = ""
  @objc dynamic var added = ""
  @objc dynamic var isCreatedInServer = false
  var tasks = List<TaskItem>()
  
  override static func primaryKey() -> String? {
    return "title"
  }
  
  convenience init(title: String) {
    self.init()
    self.title = title
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
