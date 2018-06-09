//
//  GroupCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 5. 31..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GroupCell: UITableViewCell {
  private let bag = DisposeBag()
  static let reuseIdentifier = "GroupCell"
  private var containerGuide = UILayoutGuide()
  private lazy var imgView: UIImageView = {
    let view = UIImageView()
    view.contentMode = UIViewContentMode.scaleAspectFit
    return view
  }()
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.font = UIFont.boldSystemFont(ofSize: 20)
    label.textColor = UIColor.black
    return label
  }()
  private lazy var countLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  
  func setupSubviews() {
    accessoryType = .disclosureIndicator
    addLayoutGuide(containerGuide)
    addSubview(imgView)
    addSubview(titleLabel)
    addSubview(countLabel)
    containerGuide.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(safeAreaLayoutGuide.snp.left).inset(20)
        make.right.equalTo(safeAreaLayoutGuide.snp.right).inset(20)
        make.top.equalTo(safeAreaLayoutGuide.snp.top).inset(20)
        make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(20)
      } else {
        make.edges.equalTo(self).inset(20)
      }
    }
    imgView.snp.makeConstraints { (make) in
      make.centerY.equalTo(containerGuide)
      make.left.equalTo(containerGuide)
      make.width.height.equalTo(contentView.frame.height / 2)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.top.bottom.equalTo(containerGuide)
      make.left.equalTo(imgView.snp.right).offset(10)
      make.right.equalTo(countLabel.snp.left).offset(-8)
    }
    countLabel.snp.makeConstraints { (make) in
      make.centerY.equalTo(containerGuide)
      make.right.equalTo(containerGuide).offset(-10)
      make.width.height.equalTo(imgView)
    }
  }
  
  func configureCell(model: LocalRepository) {
    setupSubviews()
    self.imgView.image = model.name == "Today" ? UIImage(named: "star") : UIImage(named: "group")
    self.titleLabel.text = model.name
    self.countLabel.text = "\(model.tasks.filter("checked = 'open'").count)"
  }
  
  override func prepareForReuse() {
    titleLabel.text = ""
    super.prepareForReuse()
  }
}
