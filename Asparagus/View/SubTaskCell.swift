//
//  SubTaskCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import Action

class SubTaskCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "SubTaskCell"
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    return label
  }()
  private lazy var checkButton: UIButton = {
    let btn = UIButton()
    return btn
  }()
  
  func setupSubviews() {
    backgroundColor = UIColor.white
    addSubview(titleLabel)
    addSubview(checkButton)
    titleLabel.snp.makeConstraints { (make) in
      make.left.equalTo(contentView).offset(10)
      make.top.equalTo(contentView.snp.top)
      make.bottom.equalTo(contentView.snp.bottom)
      make.right.equalTo(checkButton.snp.left).offset(-5)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(contentView.snp.right).offset(-10)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
    }
  }
  
  func configureCell(item: SubTask, action: CocoaAction) {
    setupSubviews()
    checkButton.rx.action = action
    item.rx.observe(String.self, "title")
      .subscribe(onNext: { [unowned self] title in
        self.titleLabel.text = title
      })
      .disposed(by: bag)
    
    item.rx.observe(String.self, "checked")
      .subscribe(onNext: { [unowned self] state in
        let image = UIImage(named: state == "open" ? "ItemNotChecked" : "ItemChecked")
        self.checkButton.setImage(image, for: .normal)
      })
      .disposed(by: bag)
  }
  
  override func prepareForReuse() {
    checkButton.rx.action = nil
    titleLabel.text = ""
    bag = DisposeBag()
    super.prepareForReuse()
  }
}
