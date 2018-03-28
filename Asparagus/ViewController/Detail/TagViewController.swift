//
//  TagViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 25..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

enum TableViewEditingCommand {
  case AppendItem(item: Tag)
  case DeleteItem(IndexPath)
}

class TagViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: DetailViewModel!
  private let container: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 10
    view.layer.shadowColor = UIColor.darkGray.cgColor
    view.layer.shadowRadius = 15
    view.layer.shadowOpacity = 0.75
    return view
  }()
  private lazy var tableView: UITableView = {
    let view = UITableView(frame: CGRect.zero, style: .grouped)
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(TagCell.self, forCellReuseIdentifier: TagCell.reuseIdentifier)
    view.backgroundColor = UIColor(hex: "4478E4")
    return view
  }()
  
  private var closeButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("CLOSE", for: .normal)
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    return btn
  }()
  
  private var editButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("Edit", for: .normal)
    return btn
  }()
  private var addTagButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("Add", for: .normal)
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    return btn
  }()
  
  func bindViewModel() {
    
    viewModel.tags()
      .bind(to: tableView.rx.items) {
        (tableView: UITableView, index: Int, item: Tag) in
        let cell = TagCell(style: .default, reuseIdentifier: TagCell.reuseIdentifier)
        cell.configureCell(tag: item)
        return cell
      }
      .disposed(by: bag)
    
    addTagButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        
      })
      .disposed(by: bag)
    
    closeButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        self.viewModel.sceneCoordinator.pop()
      })
      .disposed(by: bag)
    
    //tag 업데이트
    editButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        self.toggleEditState()
      })
      .disposed(by: bag)
    
  }
  
  func toggleEditState() {
    if tableView.isEditing {
      tableView.isEditing = false
    } else {
      tableView.isEditing = true
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    title = "Tag"
    view.addSubview(container)
    container.addSubview(closeButton)
    container.addSubview(editButton)
    container.addSubview(tableView)
    container.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 4 / 5)
      make.height.equalTo(UIScreen.main.bounds.height / 2)
    }
    editButton.snp.makeConstraints({ (make) in
      editButton.sizeToFit()
      make.right.equalTo(container).offset(-10)
      make.top.equalTo(container).offset(10)
    })
    closeButton.snp.makeConstraints({ (make) in
      closeButton.sizeToFit()
      make.left.equalTo(container).offset(10)
      make.top.equalTo(container).offset(10)
    })
    tableView.snp.makeConstraints { (make) in
      make.top.equalTo(editButton.snp.bottom).offset(10)
      make.left.right.bottom.equalTo(container)
    }
  }
}
