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
  private let containerGuide = UILayoutGuide()
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.textColor = .white
    label.backgroundColor = .clear
    label.numberOfLines = 0
    return label
  }()
  private lazy var checkButton: UIButton = {
    let btn = UIButton()
    return btn
  }()
  
  func setupSubviews() {
    selectionStyle = .none
    backgroundColor = UIColor(hex: "232429")
    addLayoutGuide(containerGuide)
    addSubview(titleLabel)
    addSubview(checkButton)
    containerGuide.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview().inset(20)
      make.top.bottom.equalToSuperview().inset(5)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.top.bottom.equalTo(containerGuide)
      make.right.equalTo(checkButton.snp.left).offset(-5)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(containerGuide)
      make.centerY.equalTo(containerGuide)
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
