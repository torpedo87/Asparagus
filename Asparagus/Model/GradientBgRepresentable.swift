//
//  GradientBgRepresentable.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

protocol GradientBgRepresentable {}

extension GradientBgRepresentable where Self: UIViewController {
  func setGradientBgColor() {
    let gradientLayer = CAGradientLayer()
    
    gradientLayer.frame = self.view.bounds
    
    gradientLayer.colors = [UIColor(hex: "084061").cgColor, UIColor.white.cgColor]
    
    self.view.layer.addSublayer(gradientLayer)
  }
}
