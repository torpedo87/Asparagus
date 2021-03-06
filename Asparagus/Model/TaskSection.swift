//
//  TaskSection.swift
//  Asparagus
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

extension TaskSection: AnimatableSectionModelType {
  typealias Item = TaskItem
  
  init(original: TaskSection, items: [Item]) {
    self = original
    self.items = items
  }
  var identity: String {
    return header
  }
}

struct SubTaskSection: AnimatableSectionModelType {
  var header: String
  var items: [Item]
}
extension SubTaskSection: SectionModelType {
  typealias Item = SubTask
  
  init(original: SubTaskSection, items: [Item]) {
    self = original
    self.items = items
  }
  var identity: String {
    return header
  }
}
