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
  private let numberLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()
  private let imgView: UIImageView = {
    let view = UIImageView(image: UIImage(named: "local"))
    return view
  }()
  private var achievementView: CircleProgressView = {
    let view = CircleProgressView(achieveRate: 0)
    view.backgroundColor = UIColor.clear
    return view
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
  
  func setupSubviews() {
    backgroundColor = UIColor.white
    addSubview(baseView)
    baseView.addSubview(numberLabel)
    baseView.addSubview(imgView)
    baseView.addSubview(achievementView)
    baseView.addSubview(titleLabel)
    baseView.addSubview(checkButton)
    baseView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(10)
    }
    achievementView.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 15)
      make.left.equalTo(baseView)
      make.centerY.equalTo(contentView)
    }
    numberLabel.snp.makeConstraints { (make) in
      make.width.height.equalTo(50)
      make.left.equalTo(achievementView.snp.right).offset(5)
      make.centerY.equalTo(contentView)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.equalTo(numberLabel.snp.right).offset(5)
      make.top.equalTo(baseView)
      make.bottom.equalTo(baseView)
      make.right.equalTo(imgView.snp.left).offset(-5)
    }
    imgView.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 25)
      make.right.equalTo(checkButton.snp.left).offset(-5)
      make.centerY.equalTo(contentView)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(baseView)
      make.centerY.equalTo(contentView)
      make.width.height.equalTo(UIScreen.main.bounds.height / 25)
    }
  }
  
  func configureCell(item: TaskItem, action: CocoaAction) {
    setupSubviews()
    checkButton.rx.action = action
    numberLabel.isHidden = !item.isServerGeneratedType
    imgView.image = item.isServerGeneratedType ? UIImage(named: "sync") : UIImage(named: "local")
    
    item.rx.observe(Int.self, "number")
      .subscribe(onNext: { [unowned self] number in
        if number != 0 {
          self.numberLabel.text = "# \(number!)"
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
