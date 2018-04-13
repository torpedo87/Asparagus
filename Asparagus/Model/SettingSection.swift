//
//  SettingSection.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 10..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxDataSources

enum License: String {
  case rxSwift
  case action
  case rxDataSource
  case rxKeyboard
  case snapKit
  case moya
  case rxRealm
  case rxGesture
  
  static let arr: [License] = [.rxSwift, .action, .rxDataSource, .rxKeyboard, .snapKit, .moya, .rxRealm, .rxGesture]
  
  func licenseUrl() -> String {
    switch self {
    case .rxSwift:
      return "https://github.com/ReactiveX/RxSwift"
    case .action:
      return "https://github.com/RxSwiftCommunity/Action"
    case .rxDataSource:
      return "https://github.com/RxSwiftCommunity/RxDataSources"
    case .rxKeyboard:
      return "https://github.com/RxSwiftCommunity/RxKeyboard"
    case .snapKit:
      return "https://github.com/SnapKit/SnapKit"
    case .moya:
      return "https://github.com/Moya/Moya"
    case .rxRealm:
      return "https://github.com/RxSwiftCommunity/RxRealm"
    case .rxGesture:
      return "https://github.com/RxSwiftCommunity/RxGesture"
    }
  }
}

enum SettingModel {
  case text(String)
  case license(License)
}


struct SettingSection {
  var header: String
  var items: [Item]
}

extension SettingSection: SectionModelType {
  typealias Item = SettingModel
  
  init(original: SettingSection, items: [Item]) {
    self = original
    self.items = items
  }
}
