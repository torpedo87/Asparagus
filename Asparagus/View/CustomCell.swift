//
//  CustomCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 23..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {
  static let reuseIdentifier = "CustomCell"
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureCell(customView: UIView) {
    addSubview(customView)
    customView.snp.makeConstraints { (make) in
      make.left.equalTo(safeAreaLayoutGuide.snp.left)
      make.top.equalTo(safeAreaLayoutGuide.snp.top)
      make.right.equalTo(safeAreaLayoutGuide.snp.right)
      make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
    }
  }
}
