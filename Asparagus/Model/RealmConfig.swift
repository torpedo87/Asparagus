//
//  RealmConfig.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 19..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmConfig {
  
  case main
  
  private static var copyInitialFile: Void = {
    LocalTaskService.copyInitialData(
      Bundle.main.url(forResource: "default_v1.0", withExtension: "realm")!,
      to: RealmConfig.mainConfig.fileURL!)
  }()
  private static let mainConfig = Realm.Configuration(
    fileURL: URL.inDocumentsFolder(fileName: "main.realm"),
    schemaVersion: 1,
    migrationBlock: LocalTaskService.migrate
  )
  var configuration: Realm.Configuration {
    switch self {
    case .main:
      _ = RealmConfig.copyInitialFile
      return RealmConfig.mainConfig
    }
  }
}
