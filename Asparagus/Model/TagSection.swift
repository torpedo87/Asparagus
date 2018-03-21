//
//  TagSection.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 14..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxDataSources

struct TagSection {
  var header: String
  var items: [Item]
}
extension TagSection: SectionModelType {
  typealias Item = Tag
  
  init(original: TagSection, items: [Item]) {
    self = original
    self.items = items
  }
}

