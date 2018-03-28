//
//  FoldableView.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class FoldableView: UIView {
  var isFolded: Bool = true
  
  func toggle() {
    if isFolded {
      UIView.animate(withDuration: 0.5) {
        self.snp.updateConstraints { make in
          make.height.equalTo(UIScreen.main.bounds.height * 4 / 5)
        }
        self.superview?.layoutIfNeeded()
      }
      self.isFolded = false
    } else {
      UIView.animate(withDuration: 0.5) {
        self.snp.updateConstraints { make in
          make.height.equalTo(UIScreen.main.bounds.height / 3)
        }
        self.superview?.layoutIfNeeded()
      }
      self.isFolded = true
    }
  }
}
