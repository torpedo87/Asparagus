//
//  SplashViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift

class SplashViewController: UIViewController, BindableType {
  
  var viewModel: SplashViewModel!
  private let bag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.green
  }
  
  //bug: DispatchQueue 사용해야만 작동함
  func bindViewModel() {
    viewModel.account
      .debug("-----account------")
      .drive(onNext: { [unowned self] status in
        switch status {
        case .authorized(_):
          DispatchQueue.main.async {
            self.viewModel.goToTaskScene()
          }
          
        case .unavailable(_):
          DispatchQueue.main.async {
            self.viewModel.goToLoginScene()
          }
          
        }
      })
      .disposed(by: bag)
  }
}
