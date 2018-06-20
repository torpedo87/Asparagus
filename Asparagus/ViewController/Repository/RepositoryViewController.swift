//
//  RepositoryViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 5. 31..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class RepositoryViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: RepositoryViewModel!
  private lazy var activityIndicator: UIActivityIndicatorView = {
    let spinner = UIActivityIndicatorView()
    spinner.color = UIColor.blue
    spinner.isHidden = false
    return spinner
  }()
  private lazy var authBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(title: "Sync",
                               style: .plain,
                               target: self,
                               action: nil)
    item.customView?.contentMode = UIViewContentMode.scaleAspectFit
    return item
  }()
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.backgroundColor = UIColor.white
    view.register(GroupCell.self,
                  forCellReuseIdentifier: GroupCell.reuseIdentifier)
    view.separatorStyle = .none
    return view
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    title = "Repository"
    navigationItem.leftBarButtonItem = authBarButtonItem
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.edges.equalTo(view)
      }
    }
  }
  
  func bindViewModel() {
    viewModel.localRepositories()
      .bind(to: tableView.rx.items) {
        (tableView: UITableView, index: Int, item: LocalRepository) in
        let cell = GroupCell(style: .default, reuseIdentifier: GroupCell.reuseIdentifier)
        cell.configureCell(model: item)
        return cell
      }
      .disposed(by: bag)
    
    tableView.rx.modelSelected(LocalRepository.self)
      .bind(to: viewModel.issueAction.inputs)
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] indexPath in
        self.tableView.deselectRow(at: indexPath, animated: false)
      })
      .disposed(by: bag)
    
    authBarButtonItem.rx.action = viewModel.onSync()
    
    viewModel.isRunning()
      .bind(to: activityIndicator.rx.isAnimating)
      .disposed(by: bag)
  }
  
}
