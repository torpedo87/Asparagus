//
//  TaskViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Action

class TaskViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: TaskViewModel!
  
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.register(TaskCell.self,
                  forCellReuseIdentifier: TaskCell.reuseIdentifier)
    view.rowHeight = UIScreen.main.bounds.height / 15
    return view
  }()
  private lazy var newTaskButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add,
                      target: self,
                      action: nil)
    return item
  }()
  private lazy var authButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(image: nil,
                      style: .plain,
                      target: self,
                      action: nil)
    return item
  }()
  
  var dataSource: RxTableViewSectionedReloadDataSource<TaskSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    title = "Task"
    view.addSubview(tableView)
    navigationItem.rightBarButtonItem = newTaskButton
    navigationItem.leftBarButtonItem = authButton
    tableView.snp.makeConstraints({ (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    })
  }
  
  func bindViewModel() {
    
    viewModel.authService.isLoggedIn.asDriver(onErrorJustReturn: false)
      .map { $0 ? "Logout" : "Login" }
      .drive(authButton.rx.title)
      .disposed(by: bag)
  
    newTaskButton.rx.action = viewModel.goToCreate()
    authButton.rx.action = viewModel.goToAuth()
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .do(onNext: { [unowned self] indexPath in
        self.tableView.deselectRow(at: indexPath, animated: false)
      })
      .map { [unowned self] indexPath in
        try! self.dataSource.model(at: indexPath) as! TaskItem
      }
      .subscribe(viewModel.editAction.inputs)
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<TaskSection> (
      configureCell: {
        [unowned self] dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier, for: indexPath) as! TaskCell
        cell.configureCell(item: item, action: self.viewModel.onToggle(task: item))
        return cell
      },
      titleForHeaderInSection: { dataSource, index in
        dataSource.sectionModels[index].header
      }
    )
  }
  
}
