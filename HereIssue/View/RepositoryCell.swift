//
//  RepositoryCell.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 14..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class RepositoryCell: UITableViewCell {
  static let reuseIdentifier = "RepositoryCell"
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    let selectedView = UIView()
    selectedView.backgroundColor = UIColor.darkGray
    selectedBackgroundView = selectedView
    backgroundColor = UIColor.clear
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureCell(repoName: String) {
    textLabel?.text = repoName
    textLabel?.textColor = UIColor.white
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    textLabel?.text = nil
  }
}

