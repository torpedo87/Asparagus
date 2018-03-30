//
//  PlusButton.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 22..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class PlusButton: UIButton {
  private var halfWidth: CGFloat {
    return bounds.width / 2
  }
  private var halfHeight: CGFloat {
    return bounds.height / 2
  }
  private let plusLineWidth: CGFloat = 3.0
  private let plusScale: CGFloat = 0.6
  
  override func draw(_ rect: CGRect) {
    let plusWidth: CGFloat = min(bounds.width, bounds.height) * plusScale
    
    let path = UIBezierPath(ovalIn: rect)
    UIColor(hex: "50A95A").setFill()
    path.fill()
    
    let plusPath = UIBezierPath()
    plusPath.lineWidth = plusLineWidth
    
    //시작점
    plusPath.move(to: CGPoint(x: halfWidth - (plusWidth / 2),
                              y: halfHeight))
    plusPath.addLine(to: CGPoint(x: halfWidth + (plusWidth / 2),
                                 y: halfHeight))
    plusPath.move(to: CGPoint(x: halfWidth,
                              y: halfHeight - (plusWidth / 2)))
    plusPath.addLine(to: CGPoint(x: halfWidth,
                                 y: halfHeight + (plusWidth / 2)))
    
    UIColor.white.setStroke()
    plusPath.stroke()
  }
}
