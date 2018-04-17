//
//  TotalSection.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 17..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxDataSources

enum MyModel {
  case inbox(String)
  case localRepo(LocalRepository)
  case tag(Tag)
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
