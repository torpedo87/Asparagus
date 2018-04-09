//
//  TagCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 14..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TagCell: UITableViewCell {
  private let bag = DisposeBag()
  static let reuseIdentifier = "TagCell"
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.textColor = UIColor(hex: "F5F5F5")
    return label
  }()
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    let selectedView = UIView()
    selectedView.backgroundColor = UIColor.darkGray
    selectedBackgroundView = selectedView
    backgroundColor = UIColor.clear
    addSubview(titleLabel)
    
    titleLabel.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(50)
        make.top.equalTo(safeAreaLayoutGuide.snp.top)
        make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-5)
        make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
      } else {
        make.left.equalTo(self).offset(50)
        make.top.bottom.equalTo(self)
        make.right.equalTo(self).offset(-5)
      }
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureCell(tag: Tag) {
    
    tag.rx.observe(String.self, "title")
      .subscribe(onNext: { [unowned self] title in
        self.titleLabel.text = "# " + (title ?? "")
      })
      .disposed(by: bag)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
  }
}
