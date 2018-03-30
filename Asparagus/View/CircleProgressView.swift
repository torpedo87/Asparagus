//
//  CircleProgressView.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 22..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class CircleProgressView: UIView {
  
  var achieveRate: CGFloat
  init(achieveRate: CGFloat) {
    self.achieveRate = achieveRate
    super.init(frame: CGRect.zero)
    backgroundColor = UIColor.white
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ rect: CGRect) {
    let circlePath = UIBezierPath(ovalIn: rect)
    UIColor(hex: "C9DF8B").setFill()
    circlePath.fill()
    
    let center = CGPoint(x: bounds.width / 2,
                         y: bounds.height / 2)
    let arcWidth = bounds.width / 2
    let radius: CGFloat = bounds.width / 2 - arcWidth / 2

    let arcPath = UIBezierPath(arcCenter: center,
                            radius: radius,
                            startAngle: CGFloat(0).toRadians(),
                            endAngle: (achieveRate * 360).toRadians(),
                            clockwise: true)
    arcPath.lineWidth = arcWidth
    UIColor(hex: "50A95A").setStroke()
    arcPath.stroke()
  }
}

extension CGFloat {
  func toRadians() -> CGFloat {
    return (self - 90) * .pi / 180.0
  }
}
