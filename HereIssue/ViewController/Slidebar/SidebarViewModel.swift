//
//  SidebarViewModel.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct SidebarViewModel {
  private let bag = DisposeBag()
  var leftViewModel: LeftViewModel
  var taskViewModel: TaskViewModel
  let menuTap = BehaviorRelay<Void>(value: ())
  let repoTap = BehaviorRelay<Void>(value: ())
  
  init(leftViewModel: LeftViewModel, taskViewModel: TaskViewModel) {
    self.leftViewModel = leftViewModel
    self.taskViewModel = taskViewModel
    
    bindOutput()
  }
  
  func bindOutput() {
    leftViewModel.selectedRepo
      .bind(to: taskViewModel.selectedRepo)
      .disposed(by: bag)
    
    leftViewModel.selectedRepo
      .map { _ in }
      .bind(to: repoTap)
      .disposed(by: bag)
    
    taskViewModel.menuTap
      .bind(to: menuTap)
      .disposed(by: bag)
    
  }
  
}
