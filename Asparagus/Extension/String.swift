//
//  String.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 24..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation

extension String {
  
  func convertToDate() -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    return dateFormatter.date(from: self)
  }
}
