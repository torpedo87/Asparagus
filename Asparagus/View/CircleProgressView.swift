//
//  CircleProgressView.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 22..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class CircleProgressView: UIView {
  
  override func draw(_ rect: CGRect) {
    let path = UIBezierPath(ovalIn: rect)
    UIColor.green.setFill()
    path.fill()
  }
}
