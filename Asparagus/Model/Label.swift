//
//  Label.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 17..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class Label: Object, Codable {
  @objc dynamic var name = ""
  
  enum CodingKeys: String, CodingKey {
    case name
  }
  
  convenience init(name: String) {
    self.init()
    self.name = name
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let name = try container.decode(String.self, forKey: .name)
    self.init(name: name)
  }
}
