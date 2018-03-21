//
//  Token.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation

struct Token: Codable {
  let id: Int
  let token: String
  
  var asDictionary: [String:Any] {
    return [
      "id": id,
      "token": token
    ]
  }
}

