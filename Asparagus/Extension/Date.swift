//
//  Date.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 24..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation

extension Date {
  func converToPastDateString() -> String {
    let date = Date(timeInterval: -3600, since: self)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter.string(from: date)
  }
  
}
