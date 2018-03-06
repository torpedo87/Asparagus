//
//  User.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object, Codable {
  @objc dynamic var name = ""
  
  enum CodingKeys: String, CodingKey {
    case name = "login"
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
