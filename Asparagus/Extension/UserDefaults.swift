//
//  UserDefaults.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation

extension UserDefaults {
  
  static func saveToken(token: Token) {
    
    let dict = token.asDictionary
    UserDefaults.standard.set(dict, forKey: "token")
  }
  
  static func loadToken() -> Token? {
    guard let dict =
      UserDefaults.standard.dictionary(forKey: "token") else { return nil }
    if let id = dict["id"] as? Int, let token = dict["token"] as? String {
      let newToken = Token(id: id, token: token)
      return newToken
    }
    return nil
  }
  
  static func removeLocalToken() {
    UserDefaults.standard.removeObject(forKey: "token")
  }
  
  static func saveMe(me: User) {
    let dict = me.asDictionary
    UserDefaults.standard.set(dict, forKey: "me")
  }
  
  static func loadUser() -> User? {
    guard let dict =
      UserDefaults.standard.dictionary(forKey: "me") else { return nil }
    if let name = dict["name"] as? String, let avatar = dict["avatar"] as? String {
      let me = User(name: name, avatar: avatar)
      return me
    }
    return nil
  }
  
  static func removeMe() {
    UserDefaults.standard.removeObject(forKey: "me")
  }
}

