//
//  Scene.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

enum Scene {
  case auth(AuthViewModel)
  case task(TaskViewModel)
  case edit(EditViewModel)
}

extension Scene {
  func viewController() -> UIViewController {
    
    switch self {
    case .auth(let viewModel):
      var vc = AuthViewController()
      vc.bindViewModel(to: viewModel)
      return vc
      
    case .task(let viewModel):
      var vc = TaskViewController()
      vc.bindViewModel(to: viewModel)
      let nav = UINavigationController(rootViewController: vc)
      return nav
    case .edit(let viewModel):
      var vc = EditViewController()
      vc.bindViewModel(to: viewModel)
      return vc
    }
  }
}
