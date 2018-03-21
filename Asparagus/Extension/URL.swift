//
//  URL.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 19..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation

extension URL {
  
  static func inDocumentsFolder(fileName: String) -> URL {
    return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], isDirectory: true)
      .appendingPathComponent(fileName)
  }
}
