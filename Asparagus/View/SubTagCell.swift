//
//  SubTagCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 29..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import Action

class SubTagCell: UITableViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "SubTagCell"
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    return label
  }()
  private var deleteButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "trash"), for: UIControlState.normal)
    return btn
  }()
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = UIColor.white
    
    addSubview(titleLabel)
    addSubview(deleteButton)
    
    titleLabel.snp.makeConstraints { (make) in
      make.left.top.bottom.equalTo(contentView).inset(10)
      make.right.equalTo(deleteButton.snp.left).offset(-5)
    }
    deleteButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.centerY.equalToSuperview()
      make.right.equalTo(contentView).offset(-10)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureCell(item: Tag, onUpdateTags: Action<(Tag, LocalTaskService.TagMode), Void>) {
    
    item.rx.observe(String.self, "title")
      .subscribe(onNext: { [unowned self] title in
        self.titleLabel.text = title!
      })
      .disposed(by: bag)
    
    deleteButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map { _ -> (Tag, LocalTaskService.TagMode) in
        return (item, LocalTaskService.TagMode.delete)
      }
      .bind(to: onUpdateTags.inputs)
      .disposed(by: bag)
  }
  
  override func prepareForReuse() {
    deleteButton.rx.action = nil
    titleLabel.text = ""
    bag = DisposeBag()
    super.prepareForReuse()
  }
}
