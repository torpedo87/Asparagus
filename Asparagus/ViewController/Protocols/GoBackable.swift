//
//  GoBackable.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action

protocol GoBackable {
  var customBackButton: UIBarButtonItem { get set }
}

extension GoBackable where Self: UIViewController {
  func setCustomBackButton() {
    navigationItem.leftBarButtonItem = customBackButton
  }
}
