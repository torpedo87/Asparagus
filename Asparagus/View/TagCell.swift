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
import RealmSwift

class TagCell: UITableViewCell {
  private let bag = DisposeBag()
  static let reuseIdentifier = "TagCell"
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.textColor = UIColor.white
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
      make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(5)
      make.top.equalTo(safeAreaLayoutGuide.snp.top)
      make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-5)
      make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
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
