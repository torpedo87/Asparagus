//
//  GroupSection.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 14..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxDataSources

struct GroupSection {
  var header: String
  var items: [Item]
}
extension GroupSection: SectionModelType {
  typealias Item = String
  
  init(original: GroupSection, items: [Item]) {
    self = original
    self.items = items
  }
}

