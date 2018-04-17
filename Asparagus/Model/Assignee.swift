//
//  Assignee.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 17..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class Assignee: Object {
  @objc dynamic var name = ""
  var tasks = List<TaskItem>()
  
  override static func primaryKey() -> String? {
    return "name"
  }
  
  convenience init(name: String) {
    self.init()
    self.name = name
  }
}
