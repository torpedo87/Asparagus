//
//  LeftViewController.swift
//  HereIssue
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
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor.white, for: .normal)
    return btn
  }()
  var viewModel: LeftViewModel!
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.backgroundColor = UIColor(hex: "2E3136")
    view.register(RepositoryCell.self,
                  forCellReuseIdentifier: RepositoryCell.reuseIdentifier)
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.separatorStyle = .none
    return view
  }()
  var dataSource: RxTableViewSectionedReloadDataSource<GroupSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    view.addSubview(tableView)
    view.addSubview(authButton)
    
    tableView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    }
    
    authButton.snp.makeConstraints { (make) in
      authButton.sizeToFit()
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-10)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
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
        try! self.dataSource.model(at: indexPath) as! String
      }
      .subscribe(onNext: { [unowned self] title in
        self.viewModel.selectedGroupTitle.accept(title)
      })
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<GroupSection> (
      configureCell: { dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: RepositoryCell.reuseIdentifier, for: indexPath) as! RepositoryCell
        cell.configureCell(repoName: item)
        return cell
      },
      titleForHeaderInSection: { dataSource, index in
        dataSource.sectionModels[index].header
    }
    )
  }
}
