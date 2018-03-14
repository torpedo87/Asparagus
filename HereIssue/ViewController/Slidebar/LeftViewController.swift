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

class LeftViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor.blue, for: .normal)
    return btn
  }()
  var viewModel: LeftViewModel!
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.register(UITableViewCell.self,
                  forCellReuseIdentifier: "TableViewCell")
    view.rowHeight = UIScreen.main.bounds.height / 15
    return view
  }()
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    view.backgroundColor = UIColor.green
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
    
    viewModel.repoList.asDriver()
      .drive(onNext: { [unowned self] _ in self.tableView.reloadData() })
      .disposed(by: bag)
    
    //datasource
    viewModel.repoList.asObservable()
      .bind(to: tableView.rx.items) {
        (tableView: UITableView, index: Int, element: String) in
        let cell =
          UITableViewCell(style: .default, reuseIdentifier: "TableViewCell")
        cell.textLabel?.text = element
        return cell
      }
      .disposed(by: bag)
    
    //delegate
    tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] indexPath in
        let selectedRepo = self.viewModel.repoList.value[indexPath.row]
        self.viewModel.selectedRepo.accept(selectedRepo)
      })
      .disposed(by: bag)
  }
}
