//
//  TaskViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm
import RxCocoa

struct TaskViewModel {
  private let bag = DisposeBag()
  let sceneCoordinator: SceneCoordinatorType
  
  init(coordinator: SceneCoordinatorType) {
    self.sceneCoordinator = coordinator
  }
}
