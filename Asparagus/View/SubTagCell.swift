//
//  SubTagCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 29..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import Action

class SubTagCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "SubTagCell"
  private let containerGuide = UILayoutGuide()
  private lazy var imgView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage(named: "tag")
    view.contentMode = .scaleAspectFit
    return view
  }()
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.backgroundColor = .clear
    label.textColor = .white
    return label
  }()
  
  func setupSubviews() {
    selectionStyle = .none
    tintColor = .white
    addLayoutGuide(containerGuide)
    backgroundColor = UIColor(hex: "232429")
    addSubview(imgView)
    addSubview(titleLabel)
    accessoryType = .none
    
    containerGuide.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(20)
    }
    imgView.snp.makeConstraints { (make) in
      make.left.equalTo(containerGuide)
      make.centerY.equalTo(containerGuide)
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.equalTo(imgView.snp.right).offset(8)
      make.top.bottom.equalTo(containerGuide)
      make.right.equalTo(containerGuide).offset(-50)
    }
  }
  
  func configureCell(item: PopupViewController.LabelMode, isTagged: Bool) {
    setupSubviews()
    titleLabel.text = item.rawValue
    imgView.image = isTagged ? UIImage(named: "tagged") : UIImage(named: "unTagged")
    accessoryType = isTagged ? .checkmark : .none
  }
  
  override func prepareForReuse() {
    titleLabel.text = ""
    accessoryType = .none
    bag = DisposeBag()
    super.prepareForReuse()
  }
}
