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
  private lazy var baseView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()
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
    backgroundColor = UIColor(hex: "232429")
    addSubview(baseView)
    baseView.addSubview(titleLabel)
    baseView.addSubview(checkButton)
    baseView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(8)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.top.bottom.equalTo(baseView)
      make.right.equalTo(checkButton.snp.left).offset(-5)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(baseView)
      make.centerY.equalTo(baseView)
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
