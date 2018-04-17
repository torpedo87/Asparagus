//
//  TagCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 14..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TagCell: UITableViewCell {
  private let bag = DisposeBag()
  static let reuseIdentifier = "TagCell"
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.textColor = UIColor(hex: "F5F5F5")
    return label
  }()
  
  func setupSubviews() {
    let selectedView = UIView()
    selectedView.backgroundColor = UIColor.darkGray
    selectedBackgroundView = selectedView
    backgroundColor = UIColor.clear
    addSubview(titleLabel)
    titleLabel.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(50)
        make.top.equalTo(safeAreaLayoutGuide.snp.top)
        make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-5)
        make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
      } else {
        make.left.equalTo(self).offset(50)
        make.top.bottom.equalTo(self)
        make.right.equalTo(self).offset(-5)
      }
    }
  }
  
  func configureCell(model: MyModel) {
    setupSubviews()
    switch model {
    case .inbox(_): do {
      self.titleLabel.text = "Inbox"
      }
    case .localRepo(let localRepo): do {
      self.titleLabel.text = localRepo.name
      }
    case .tag(let label): do {
      self.titleLabel.text = label.title
      }
    }
  }
  
  override func prepareForReuse() {
    titleLabel.text = ""
    super.prepareForReuse()
  }
}
