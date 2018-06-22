//
//  NewTaskCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 28..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action

class NewTaskCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "NewTaskCell"
  private let containerGuide = UILayoutGuide()
  
  private lazy var numberLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()
  
  private lazy var titleTextField: UITextField = {
    let view = UITextField()
    view.textColor = .white
    return view
  }()
  private lazy var addButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "add"), for: UIControlState.normal)
    return btn
  }()
  
  func setupSubviews() {
    selectionStyle = .none
    backgroundColor = UIColor(hex: "232429")
    addLayoutGuide(containerGuide)
    addSubview(titleTextField)
    addSubview(addButton)
    containerGuide.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview().inset(20)
      make.top.bottom.equalToSuperview().inset(5)
    }
    titleTextField.snp.makeConstraints { (make) in
      make.left.top.bottom.equalTo(containerGuide)
      make.right.equalTo(addButton.snp.left).offset(-5)
    }
    addButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.centerY.right.equalTo(containerGuide)
    }
  }
  
  func configureCell(onAddTasks: Action<String, Void>) {
    setupSubviews()
    addButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> String in
        if let title = self.titleTextField.text {
          return title
        }
        return ""
      })
      .filter{ $0 != ""}
      .bind(to: onAddTasks.inputs)
      .disposed(by: bag)
  }
  
  func configureNewTagCell(onUpdateTags: Action<(Tag, LocalTaskService.EditMode), Void>) {
    setupSubviews()
    addButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .filter{return self.titleTextField.text != nil}
      .map { _ -> (Tag, LocalTaskService.EditMode) in
        let title = self.titleTextField.text!.lowercased()
        let newTag = Tag(title: title)
        newTag.setDateWhenCreated()
        return (newTag, LocalTaskService.EditMode.add)
      }.bind(to: onUpdateTags.inputs)
      .disposed(by: bag)
  }
  
  override func prepareForReuse() {
    addButton.rx.action = nil
    bag = DisposeBag()
    titleTextField.text = ""
    super.prepareForReuse()
  }
}
