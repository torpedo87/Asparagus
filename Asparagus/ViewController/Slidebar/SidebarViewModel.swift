//
//  SidebarViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct SidebarViewModel {
  private let bag = DisposeBag()
  private var leftViewModel: LeftViewModel
  private var taskViewModel: TaskViewModel
  let menuTap = PublishSubject<Void>()
  let repoTap = PublishSubject<Void>()
  
  init(leftViewModel: LeftViewModel, taskViewModel: TaskViewModel) {
    self.leftViewModel = leftViewModel
    self.taskViewModel = taskViewModel
    
    bindOutput()
  }
  
  func bindOutput() {
    leftViewModel.selectedGroupTitle
      .bind(to: taskViewModel.selectedGroupTitle)
      .disposed(by: bag)
    
    leftViewModel.selectedGroupTitle
      .map { _ in }
      .bind(to: repoTap)
      .disposed(by: bag)
    
    taskViewModel.menuTap
      .bind(to: menuTap)
      .disposed(by: bag)
  }
  
}
