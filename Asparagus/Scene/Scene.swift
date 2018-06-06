//
//  Scene.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

enum Scene {
  case auth(AuthViewModel)
  case repository(RepositoryViewModel)
  case issue(IssueViewModel)
  case issueDetail(IssueDetailViewModel)
  case popup(IssueDetailViewModel, PopupMode)
  case sync(SyncViewModel)
}

extension Scene {
  
  func viewController() -> UIViewController {
    switch self {
    case .auth(let viewModel):
      var vc = AuthViewController()
      vc.bindViewModel(to: viewModel)
      return vc
    case .repository(let viewModel):
      var vc = RepositoryViewController()
      vc.bindViewModel(to: viewModel)
      let nav = UINavigationController(rootViewController: vc)
      if #available(iOS 11.0, *) {
        nav.navigationBar.prefersLargeTitles = true
      } else {
        // Fallback on earlier versions
      }
      return nav
    case .issue(let viewModel):
      var vc = IssueViewController()
      vc.bindViewModel(to: viewModel)
      return vc
    case .issueDetail(let viewModel):
      var vc = IssueDetailViewController()
      vc.bindViewModel(to: viewModel)
      return vc
    case .popup(let viewModel, let mode):
      var vc = PopupViewController()
      vc.popupMode = mode
      vc.modalPresentationStyle = .overFullScreen
      vc.bindViewModel(to: viewModel)
      return vc
    case .sync(let viewModel):
      var vc = SyncViewController()
      vc.bindViewModel(to: viewModel)
      let nav = UINavigationController(rootViewController: vc)
      nav.modalPresentationStyle = UIModalPresentationStyle.popover
      
      if let popover = nav.popoverPresentationController {
        popover.sourceView = vc.view
        popover.sourceRect = vc.view.frame
        popover.canOverlapSourceViewRect = true
        popover.delegate = vc
        popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
      }
//      nav.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 50,
//                                        height: UIScreen.main.bounds.height * 2 / 3)
      
      return nav
    }
    
  }
}
