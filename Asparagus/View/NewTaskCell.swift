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
import RealmSwift

class NewTaskCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "NewTaskCell"
  private let numberLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    return label
  }()
  
  private let titleTextField: UITextField = {
    let view = UITextField()
    view.placeholder = "add newItem"
    return view
  }()
  private var addButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("ADD", for: .normal)
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    return btn
  }()
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = UIColor.white
    addSubview(titleTextField)
    addSubview(addButton)
    
    titleTextField.snp.makeConstraints { (make) in
      make.left.top.bottom.equalTo(self).inset(10)
      make.right.equalTo(addButton.snp.left).offset(-5)
    }
    addButton.snp.makeConstraints { (make) in
      addButton.sizeToFit()
      make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-5)
      make.centerY.equalTo(contentView)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureCell(vm: DetailViewModel) {
    addButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        if let title = self.titleTextField.text {
          if !title.isEmpty {
            vm.addSubTask(title: title)
            self.titleTextField.text = nil
          }
        }
      })
      .disposed(by: bag)
  }
  
  func configureNewTagCell(vm: DetailViewModel) {
    addButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .filter{return self.titleTextField.text != nil}
      .map { _ -> (Tag, LocalTaskService.TagMode) in
        let title = self.titleTextField.text!
        let newTag = Tag(title: title, added: "", isCreatedInServer: false)
        newTag.setDateWhenCreated()
        return (newTag, LocalTaskService.TagMode.add)
      }.bind(to: vm.onUpdateTags.inputs)
      .disposed(by: bag)
  }
  
  override func prepareForReuse() {
    addButton.rx.action = nil
    bag = DisposeBag()
    super.prepareForReuse()
  }
}
