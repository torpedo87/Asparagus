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
  private var metaLabels = [UILabel]()
  private let containerGuide = UILayoutGuide()
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
  private lazy var starButton: UIButton = {
    let btn = UIButton()
    return btn
  }()
  private lazy var metaLabelView: UIView = {
    let view = UIView()
    return view
  }()
  private lazy var assigneeView: UIView = {
    let view = UIView()
    return view
  }()
  
  func setupSubviews() {
    backgroundColor = UIColor.white
    addLayoutGuide(containerGuide)
    addSubview(metaLabelView)
    addSubview(numberLabel)
    addSubview(achievementView)
    addSubview(titleLabel)
    addSubview(assigneeView)
    addSubview(checkButton)
    addSubview(starButton)
    
    containerGuide.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(20)
    }
    metaLabelView.snp.makeConstraints { (make) in
      make.top.equalTo(containerGuide.snp.bottom)
      make.left.right.equalTo(titleLabel)
      make.bottom.equalToSuperview()
    }
    numberLabel.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.left.equalTo(containerGuide)
      make.centerY.equalTo(containerGuide)
    }
    achievementView.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.left.equalTo(numberLabel.snp.right).offset(8)
      make.centerY.equalTo(containerGuide)
    }
    titleLabel.snp.makeConstraints { (make) in
      make.left.equalTo(achievementView.snp.right).offset(15)
      make.top.equalTo(containerGuide)
      make.bottom.equalTo(containerGuide)
      make.right.equalTo(checkButton.snp.left)
    }
    checkButton.snp.makeConstraints { (make) in
      make.right.equalTo(starButton.snp.left).offset(-8)
      make.centerY.equalTo(containerGuide)
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
    }
    starButton.snp.makeConstraints { (make) in
      make.right.equalTo(containerGuide)
      make.centerY.equalTo(containerGuide)
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
    }
    
    metaLabels.forEach {
      metaLabelView.addSubview($0)
    }
    
    var lastLabel: UILabel?
    for i in 0..<metaLabels.count {
      let label = metaLabels[i]
      label.sizeToFit()
      if i == 0 {
        label.snp.makeConstraints {
          $0.left.equalTo(metaLabelView)
            .offset(5)
          $0.centerY.equalTo(metaLabelView)
        }
      } else {
        label.snp.makeConstraints {
          if let last = lastLabel {
            $0.left.equalTo(last.snp.right).offset(5)
            $0.centerY.equalTo(metaLabelView)
          }
        }
      }
      lastLabel = label
    }
    
  }
  
  func configureCell(item: TaskItem, checkAction: CocoaAction, starAction: CocoaAction) {
    checkButton.rx.action = checkAction
    starButton.rx.action = starAction
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
    
    item.rx.observe(Bool.self, "isStarred")
      .subscribe(onNext: { [unowned self] bool in
        let image = UIImage(named: bool! ? "starred" : "unstarred")
        self.starButton.setImage(image, for: .normal)
      })
      .disposed(by: bag)
    
    item.rx.observe(List<Label>.self, "labels")
      .subscribe(onNext: { [unowned self] _ in
        let tags = item.labels.toArray()
        for i in 0..<tags.count {
          let label = UILabel()
          label.layer.borderWidth = 0.5
          label.font = UIFont.systemFont(ofSize: 10)
          label.text = tags[i].name
          self.metaLabels.append(label)
        }
      })
      .disposed(by: bag)
    
    setupSubviews()
  }
  
  override func prepareForReuse() {
    checkButton.rx.action = nil
    starButton.rx.action = nil
    titleLabel.text = ""
    bag = DisposeBag()
    super.prepareForReuse()
    metaLabels = []
    
    metaLabelView.subviews.forEach {
      $0.removeFromSuperview()
    }
    
  }
}
