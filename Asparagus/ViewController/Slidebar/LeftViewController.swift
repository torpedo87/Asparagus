//
//  LeftViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Action

class LeftViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: LeftViewModel!
  private lazy var topView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hex: "283A45")
    return view
  }()
  private lazy var appLabel: UILabel = {
    let label = UILabel()
    label.text = "Asparagus"
    label.textColor = UIColor.white
    return label
  }()
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.layer.cornerRadius = 10
    btn.backgroundColor = UIColor(hex: "2676AC")
    btn.setTitleColor(UIColor.white, for: .normal)
    return btn
  }()
  
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.backgroundColor = UIColor.clear
    view.register(TagCell.self,
                  forCellReuseIdentifier: TagCell.reuseIdentifier)
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.separatorStyle = .none
    view.delegate = self
    return view
  }()
  private var dataSource: RxTableViewSectionedReloadDataSource<TagSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    view.backgroundColor = UIColor(hex: "283A45")
    topView.addSubview(appLabel)
    topView.addSubview(authButton)
    view.addSubview(topView)
    view.addSubview(tableView)
    topView.snp.makeConstraints { (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.height.equalTo(50)
      make.bottom.equalTo(tableView.snp.top)
    }
    appLabel.snp.makeConstraints { (make) in
      appLabel.sizeToFit()
      make.centerY.equalTo(topView)
      make.left.equalTo(topView).offset(10)
    }
    authButton.snp.makeConstraints { (make) in
      make.height.equalTo(30)
      make.width.equalTo(100)
      make.centerY.equalTo(topView)
      make.right.equalTo(topView).offset(-10)
    }
    tableView.snp.makeConstraints { (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    }
  }
  
  func bindViewModel() {
    authButton.rx.action = viewModel.goToAuth()
    
    viewModel.isLoggedIn.asDriver(onErrorJustReturn: false)
      .map { $0 ? "Disconnect" : "Connect" }
      .drive(authButton.rx.title())
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    tableView.rx
      .modelSelected(Tag.self)
      .map({ (tag) -> String in
        return tag.title
      })
      .bind(to: viewModel.selectedGroupTitle)
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<TagSection> (
      configureCell: { dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: TagCell.reuseIdentifier,
                                                 for: indexPath) as! TagCell
        cell.configureCell(tag: item)
        return cell
      },
      titleForHeaderInSection: { dataSource, index in
        dataSource.sectionModels[index].header
    }
    )
  }
}

extension LeftViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView,
                 willDisplayHeaderView view: UIView,
                 forSection section: Int) {
    view.tintColor = UIColor(hex: "283A45")
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor.white
  }
}
