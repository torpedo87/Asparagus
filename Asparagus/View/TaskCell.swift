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
import RealmSwift

// TODO: 뷰가 램을 알지 못하게 개선하기
class TaskCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "TaskCell"
  
  private lazy var baseView: UIView = {
    let view = UIView()
    return view
  }()
  
  private lazy var numberLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  private lazy var achievementView: CircleProgressView = {
    let view = CircleProgressView(achieveRate: 0)
    view.backgroundColor = UIColor.clear
    return view
  }()
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.numberOfLines = 0
    return label
  }()
  private lazy var checkButton: UIButton = {
    let btn = UIButton()
    return btn
  }()
  
  func setupSubviews() {
    backgroundColor = UIColor.white
    addSubview(baseView)
    
    baseView.addSubview(numberLabel)
    baseView.addSubview(achievementView)
    baseView.addSubview(titleLabel)
    baseView.addSubview(checkButton)
    
    baseView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(20)
    }
    
    numberLabel.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.left.equalTo(baseView)
      make.centerY.equalTo(baseView)
    }
    achievementView.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.left.equalTo(numberLabel.snp.right).offset(8)
      make.centerY.equalTo(baseView)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.equalTo(achievementView.snp.right).offset(15)
      make.top.equalTo(baseView)
      make.bottom.equalTo(baseView)
      make.right.equalTo(checkButton.snp.left).offset(-15)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(baseView)
      make.centerY.equalTo(baseView)
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
    }
  }
  
  func configureCell(item: TaskItem, action: CocoaAction) {
    setupSubviews()
    checkButton.rx.action = action
    numberLabel.isHidden = !item.isServerGeneratedType
    backgroundColor = item.isServerGeneratedType ? UIColor.white : UIColor(hex: "F5F5F5")
    
    item.rx.observe(Int.self, "number")
      .subscribe(onNext: { [unowned self] number in
        if number != 0 {
          self.numberLabel.text = "#\(number!)"
        }
      })
      .disposed(by: bag)
    
    item.rx.observe(String.self, "title")
      .subscribe(onNext: { [unowned self] title in
        self.titleLabel.text = title!
      })
      .disposed(by: bag)
    
    item.rx.observe(List<SubTask>.self, "subTasks")
      .subscribeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        self.achievementView.achieveRate = item.achievementRate
        self.achievementView.setNeedsDisplay()
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
