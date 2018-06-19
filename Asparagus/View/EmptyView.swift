//
//  EmptyView.swift
//  Asparagus
//
//  Created by junwoo on 19/06/2018.
//  Copyright © 2018 samchon. All rights reserved.
//

import UIKit

class EmptyView: UIView {
  
  private lazy var imgView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage(named: "asparagus")
    view.contentMode = .scaleAspectFit
    return view
  }()
  private lazy var infoLabel: UILabel = {
    let label = UILabel()
    label.text = "No issues"
    label.textAlignment = .center
    return label
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupView() {
    backgroundColor = .white
    addSubview(imgView)
    addSubview(infoLabel)
    
    imgView.snp.makeConstraints {
      $0.width.height.equalTo(50)
      $0.top.equalToSuperview().offset(UIScreen.main.bounds.height / 4)
      $0.centerX.equalToSuperview()
    }
    infoLabel.sizeToFit()
    infoLabel.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(imgView.snp.bottom).offset(50)
    }
  }
  
}
