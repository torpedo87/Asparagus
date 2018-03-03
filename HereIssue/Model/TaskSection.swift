//
//  TaskSection.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxDataSources

struct TaskSection {
  var header: String
  var items: [Item]
}
extension TaskSection: SectionModelType {
  typealias Item = TaskItem
  
  init(original: TaskSection, items: [Item]) {
    self = original
    self.items = items
  }
}
