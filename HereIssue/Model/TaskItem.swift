//
//  TaskItem.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class TaskItem: Object {
  @objc dynamic var uid: Int = 0
  @objc dynamic var title: String = ""
  
  @objc dynamic var added: Date = Date()
  @objc dynamic var checked: Date? = nil
  
  override class func primaryKey() -> String? {
    return "uid"
  }
}
