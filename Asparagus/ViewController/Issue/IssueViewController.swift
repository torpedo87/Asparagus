//
//  IssueViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Action

class IssueViewController: UIViewController, BindableType, GoBackable {
  
  private let bag = DisposeBag()
  var viewModel: IssueViewModel!
  private lazy var createBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(barButtonSystemItem: .add,
                               target: self,
                               action: nil)
    return item
  }()
  private lazy var searchController: UISearchController = {
    let controller = UISearchController(searchResultsController: nil)
    controller.obscuresBackgroundDuringPresentation = false
    controller.searchBar.placeholder = "Please enter keywords"
    return controller
  }()
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.register(TaskCell.self,
                  forCellReuseIdentifier: TaskCell.reuseIdentifier)
    view.backgroundColor = UIColor.clear
    view.delegate = self
    //dynamic cell height
    view.rowHeight = UITableViewAutomaticDimension
    view.estimatedRowHeight = 140
    return view
  }()
  
  internal lazy var customBackButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(title: "BACK",
                      style: UIBarButtonItemStyle.plain,
                      target: self,
                      action: nil)
    return item
  }()
  
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TaskSection>!
  private lazy var emptyView = EmptyView(frame: CGRect(x: 0,
                                                       y: 0,
                                                       width: UIScreen.main.bounds.width,
                                                       height: UIScreen.main.bounds.height))
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    view.backgroundColor = UIColor.white
    if #available(iOS 11.0, *) {
      navigationItem.searchController = searchController
    } else {
      // Fallback on earlier versions
    }
    navigationItem.rightBarButtonItem = createBarButtonItem
    
    navigationItem.hidesBackButton = true
    setCustomBackButton()
    title = viewModel.selectedRepo.name
    view.addSubview(tableView)
    
    tableView.snp.makeConstraints({ (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.edges.equalTo(view)
      }
    })
  }
  
  func bindViewModel() {
    viewModel.sectionedItems
      .observeOn(MainScheduler.instance)
      .subscribeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] sections in
        self.hideTableviewHeader(sections: sections, i: 1)
        self.addFooterViewWhenEmpty(sections: sections)
      })
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    searchController.searchBar.rx.text.orEmpty
      .bind(to: viewModel.searchText)
      .disposed(by: bag)
    
    searchController.searchBar.rx.cancelButtonClicked
      .map{ "" }
      .bind(to: viewModel.searchText)
      .disposed(by: bag)
    
    tableView.rx.modelSelected(TaskItem.self)
      .bind(to: viewModel.editAction.inputs)
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] indexPath in
        self.tableView.deselectRow(at: indexPath, animated: false)
      })
      .disposed(by: bag)
    
    customBackButton.rx.action = viewModel.popView()
    createBarButtonItem.rx.action = viewModel.onCreateTask()
  }
  
  func hideTableviewHeader(sections: [TaskSection], i: Int) {
    if sections[i].items.count == 0 {
      self.tableView.headerView(forSection: i)?.isHidden = true
    } else {
      self.tableView.headerView(forSection: i)?.isHidden = false
    }
  }
  
  func addFooterViewWhenEmpty(sections: [TaskSection]) {
    if sections[0].items.count + sections[1].items.count == 0 {
      self.tableView.tableFooterView = emptyView
    }
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedAnimatedDataSource<TaskSection> (
      configureCell: {
        [unowned self] dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier,
                                                 for: indexPath) as! TaskCell
        cell.configureCell(item: item,
                           checkAction: self.viewModel.onToggle(task: item),
                           starAction: self.viewModel.onStar(task: item))
        return cell
      },
      titleForHeaderInSection: { dataSource, index in
        dataSource.sectionModels[index].header
    }
    )
  }
}

extension IssueViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView,
                 forSection section: Int) {
    view.tintColor = UIColor.white
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor(hex: "2E3136")
  }
}
