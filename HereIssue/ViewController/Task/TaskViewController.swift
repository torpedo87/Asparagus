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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    view.addSubview(tableView)
    
    tableView.snp.makeConstraints({ (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    })
  }
  
  func bindViewModel() {
    
    viewModel.tasks.asDriver(onErrorJustReturn: [])
      .drive(onNext: { [unowned self] _ in self.tableView.reloadData() })
      .disposed(by: bag)
    
    //datasource
    viewModel.tasks.asObservable()
      .bind(to: tableView.rx.items) {
        [unowned self] (tableView: UITableView, index: Int, element: TaskItem) in
        let cell =
          TaskCell(style: .default, reuseIdentifier: TaskCell.reuseIdentifier)
        cell.configureCell(item: element, action: self.viewModel.onToggle(task: element))
        return cell
      }
      .disposed(by: bag)
    
  }
  
  
  
}
