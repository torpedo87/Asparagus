//
//  User.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object, Codable {
  @objc dynamic var name = ""
  @objc dynamic var avatar = ""
  
  enum CodingKeys: String, CodingKey {
    case name = "login"
    case avatar = "avatar_url"
  }
  
  var asDictionary: [String:Any] {
    return [
      "name": name,
      "avatar": avatar
    ]
  }
  
  var imgUrl: URL? {
    if let url = URL(string: self.avatar) {
      return url
    } else {
      return nil
    }
  }
  
  convenience init(name: String, avatar: String = "") {
    self.init()
    self.name = name
    self.avatar = avatar
  }
  
  convenience required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let name = try container.decode(String.self, forKey: .name)
    let avatar = try container.decode(String.self, forKey: .avatar)
    self.init(name: name, avatar: avatar)
  }
}
