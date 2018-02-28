//
//  Issue.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

class Issue: Object, Codable {
  @objc dynamic var uid = 0
  @objc dynamic var title = ""
  @objc dynamic var body = ""
}
