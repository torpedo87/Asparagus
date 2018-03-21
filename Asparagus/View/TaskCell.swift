//
//  TaskCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import Action

class TaskCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "TaskCell"
  private let numberLabel: UILabel = {
    let label = UILabel()
    return label
  }()
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    return label
  }()
  private var checkButton: UIButton = {
    let btn = UIButton()
    return btn
  }()
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    addSubview(numberLabel)
    addSubview(titleLabel)
    addSubview(checkButton)
    
    numberLabel.snp.makeConstraints { (make) in
      make.width.height.equalTo(50)
      make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(10)
      make.centerY.equalTo(contentView)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.equalTo(numberLabel.snp.right).offset(5)
      make.top.equalTo(safeAreaLayoutGuide.snp.top)
      make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
      make.right.equalTo(checkButton.snp.left).offset(-5)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-10)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(50)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureCell(item: TaskItem, action: CocoaAction) {
    checkButton.rx.action = action
    
    item.rx.observe(Int.self, "number")
      .subscribe(onNext: { [unowned self] number in
        self.numberLabel.text = "\(number!)"
      })
      .disposed(by: bag)
    
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
    bag = DisposeBag()
    super.prepareForReuse()
  }
}
