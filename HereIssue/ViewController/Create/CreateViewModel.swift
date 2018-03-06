//
//  CreateViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 5..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct CreateViewModel {
  
  let onCancel: CocoaAction!
  let onCreate: Action<(String, String, String), Void>
  let bag = DisposeBag()
  let repoTitles = BehaviorRelay<[String]>(value: [])
  let localTaskService: LocalTaskServiceType
  
  init(coordinator: SceneCoordinatorType,
       createAction: Action<(String, String, String), Void>,
       localTaskService: LocalTaskServiceType) {
    self.onCreate = createAction
    self.localTaskService = localTaskService
    
    onCancel = CocoaAction {
      return coordinator.pop()
        .asObservable().map { _ in }
    }
    
    onCreate.executionObservables
      .take(1)
      .subscribe(onNext: { _ in
        coordinator.pop()
      })
      .disposed(by: bag)
    
    
    bindOutput()
  }
  
  func bindOutput() {
    localTaskService.repositories()
      .map { results -> [String] in
        let titles = results.map { $0.name }
        let filteredTitles = Array(Set(titles))
        return filteredTitles
      }.asDriver(onErrorJustReturn: [])
      .drive(repoTitles)
      .disposed(by: bag)
  }
}

