//
//  Scene.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

enum Scene {
  case splash(SplashViewModel)
  case login(LoginViewModel)
  case task(TaskViewModel)
}

extension Scene {
  func viewController() -> UIViewController {
    
    switch self {
    case .splash(let viewModel):
      var vc = SplashViewController()
      vc.bindViewModel(to: viewModel)
      return vc
      
    case .login(let viewModel):
      var vc = LoginViewController()
      vc.bindViewModel(to: viewModel)
      return vc
      
    case .task(let viewModel):
      var vc = TaskViewController()
      vc.bindViewModel(to: viewModel)
      let nav = UINavigationController(rootViewController: vc)
      return nav
    }
  }
}
