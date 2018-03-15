//
//  Repository.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class Repository: Object, Decodable {
  @objc dynamic var name = ""
  @objc dynamic var uid = ""
  @objc dynamic var owner: User?
  
  enum CodingKeys: String, CodingKey {
    case uid = "id"
    case name
    case owner
  }
  
  convenience init(uid: String = UUID().uuidString, name: String, owner: User?) {
    self.init()
    self.uid = uid
    self.name = name
    self.owner = owner
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let intId = try container.decode(Int.self, forKey: .uid)
    let uid = "\(intId)"
    let name = try container.decode(String.self, forKey: .name)
    let owner = try container.decodeIfPresent(User.self, forKey: .owner)
    self.init(uid: uid, name: name, owner: owner)
  }
}

extension Repository: Encodable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(Int(uid), forKey: .uid)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(owner, forKey: .owner)
  }
}
