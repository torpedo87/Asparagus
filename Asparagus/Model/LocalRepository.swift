//
//  LocalRepository.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 17..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class LocalRepository: Object {
  @objc dynamic var name = ""
  @objc dynamic var uid = ""
  var tasks = List<TaskItem>()
  
  override static func primaryKey() -> String? {
    return "uid"
  }
  
  convenience init(uid: String, name: String) {
    self.init()
    self.name = name
    self.uid = uid
  }
}

