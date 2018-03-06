//
//  Repository.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class Repository: Object, Codable {
  @objc dynamic var name = ""
  @objc dynamic var uid = 0
  @objc dynamic var owner: User?
  
  enum CodingKeys: String, CodingKey {
    case uid = "id"
    case name
    case owner
  }
  
  convenience init(uid: Int, name: String, owner: User) {
    self.init()
    self.uid = uid
    self.name = name
    self.owner = owner
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let uid = try container.decode(Int.self, forKey: .uid)
    let name = try container.decode(String.self, forKey: .name)
    let owner = try container.decode(User.self, forKey: .owner)
    self.init(uid: uid, name: name, owner: owner)
  }
}
