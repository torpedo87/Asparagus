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

class LeftViewController: UIViewController, BindableType, GradientBgRepresentable {
  private let bag = DisposeBag()
  private let topView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.clear
    return view
  }()
  private let appLabel: UILabel = {
    let label = UILabel()
    label.text = "Asparagus"
    label.textColor = UIColor.white
    return label
  }()
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor.white, for: .normal)
    return btn
  }()
  var viewModel: LeftViewModel!
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
  var dataSource: RxTableViewSectionedReloadDataSource<TagSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setGradientBgColor()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    view.backgroundColor = UIColor.white
    topView.addSubview(appLabel)
    topView.addSubview(authButton)
    view.addSubview(topView)
    view.addSubview(tableView)
    
    topView.snp.makeConstraints { (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.height.equalTo(45)
      make.bottom.equalTo(tableView.snp.top)
    }
    appLabel.snp.makeConstraints { (make) in
      appLabel.sizeToFit()
      make.center.equalTo(topView)
    }
    authButton.snp.makeConstraints { (make) in
      authButton.sizeToFit()
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
      .map { $0 ? "Logout" : "Login" }
      .drive(authButton.rx.title())
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .map { [unowned self] indexPath in
        try! self.dataSource.model(at: indexPath) as! Tag
      }
      .subscribe(onNext: { [unowned self] group in
        self.viewModel.selectedGroupTitle.accept(group.title)
      })
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<TagSection> (
      configureCell: { dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: TagCell.reuseIdentifier, for: indexPath) as! TagCell
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
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = UIColor.clear
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor.white
  }
}
