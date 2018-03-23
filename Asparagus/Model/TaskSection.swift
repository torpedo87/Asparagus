//
//  TaskSection.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxDataSources

enum MyModel {
  case text(String)
  case subTask(SubTask)
}

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

struct TotalSection {
  var header: String
  var items: [Item]
}
extension TotalSection: SectionModelType {
  typealias Item = MyModel
  
  init(original: TotalSection, items: [Item]) {
    self = original
    self.items = items
  }
}
