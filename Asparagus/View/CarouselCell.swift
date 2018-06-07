//
//  CarouselCell.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 6..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import Action

// TODO: 뷰가 램을 알지 못하게 개선하기

class CarouselCell: UICollectionViewCell {
  private var bag = DisposeBag()
  static let reuseIdentifier = "CarouselCell"
  private var isChecked: Bool = false
  lazy var selectedView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.lightGray
    return view
  }()
  lazy var imgView: UIImageView = {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFill
    imgView.clipsToBounds = true
    return imgView
  }()
  private lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.adjustsFontSizeToFitWidth = true
    label.textAlignment = .center
    return label
  }()
  
  func setupSubviews() {
    backgroundColor = .white
    addSubview(selectedView)
    selectedView.addSubview(imgView)
    addSubview(nameLabel)
    
    selectedView.snp.makeConstraints { (make) in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.width.height.equalTo(contentView.frame.height * 2 / 3)
      selectedView.layer.cornerRadius = contentView.frame.height / 3
    }
    imgView.snp.makeConstraints { (make) in
      make.center.equalTo(selectedView)
      make.width.height.equalTo(contentView.frame.height * 2 / 3 - 10)
      imgView.layer.cornerRadius = contentView.frame.height / 3 - 5
    }
    nameLabel.snp.makeConstraints { (make) in
      make.bottom.centerX.equalToSuperview()
      make.top.equalTo(selectedView.snp.bottom).offset(5)
      make.width.equalTo(contentView.frame.height * 2 / 3)
    }
  }
  
  func toggleCheck() {
    selectedView.backgroundColor = isChecked ? .white : .lightGray
    isChecked = !isChecked
  }
  
  func configCell(item: User, isAssigned: Bool) {
    setupSubviews()
    isChecked = isAssigned
    nameLabel.text = item.name
    if let imgUrl = item.imgUrl {
      do {
        let imgData = try Data(contentsOf: imgUrl)
        self.imgView.image = UIImage(data: imgData)
      } catch {
        self.imgView.image = UIImage(named: "user")
      }
    } else {
      self.imgView.image = UIImage(named: "user")
    }
    
    selectedView.backgroundColor = isAssigned ? .lightGray : .white
  }
  
  override func prepareForReuse() {
    bag = DisposeBag()
    super.prepareForReuse()
  }
}
