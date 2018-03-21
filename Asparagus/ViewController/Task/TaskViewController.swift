//
//  TaskViewController.swift
//  Asparagus
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
  private lazy var searchButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(title: "SEARCH",
                      style: UIBarButtonItemStyle.plain,
                      target: self,
                      action: nil)
    return item
  }()
  lazy var menuButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(image: UIImage(named: "menu"),
                      style: .plain,
                      target: self,
                      action: nil)
    return item
  }()
  
  lazy var newTaskButton: UIButton = {
    let btn = UIButton()
    btn.backgroundColor = UIColor.white
    btn.layer.cornerRadius = 25
    btn.setImage(UIImage(named: "add"), for: .normal)
    return btn
  }()
  private let activityIndicator: UIActivityIndicatorView = {
    let spinner = UIActivityIndicatorView()
    spinner.color = UIColor.blue
    spinner.isHidden = false
    return spinner
  }()
  private lazy var blurEffectView: UIVisualEffectView = {
    let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.light)
    let view = UIVisualEffectView(effect: darkBlur)
    view.isHidden = true
    return view
  }()
  private lazy var searchTableView: UITableView = {
    let view = UITableView()
    view.register(TaskCell.self,
                  forCellReuseIdentifier: TaskCell.reuseIdentifier)
    view.rowHeight = UIScreen.main.bounds.height / 15
    return view
  }()
  
  private lazy var searchBar: UISearchBar = {
    let bar = UISearchBar()
    bar.isHidden = true
    return bar
  }()
  
  var dataSource: RxTableViewSectionedReloadDataSource<TaskSection>!
  var searchDataSource: RxTableViewSectionedReloadDataSource<TaskSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    title = "Task"
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
    view.addSubview(newTaskButton)
    view.addSubview(blurEffectView)
    blurEffectView.contentView.addSubview(searchTableView)
    navigationItem.rightBarButtonItem = searchButton
    navigationItem.leftBarButtonItem = menuButton
    
    tableView.snp.makeConstraints({ (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    })
    activityIndicator.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 10)
      make.center.equalToSuperview()
    }
    newTaskButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(50)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-10)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
    }
    blurEffectView.snp.makeConstraints { (make) in
      make.edges.equalTo(tableView)
    }
    
    searchTableView.snp.makeConstraints { (make) in
      make.left.top.right.equalTo(blurEffectView.contentView)
    }
    
    
  }
  
  func bindViewModel() {
    newTaskButton.rx.action = viewModel.goToCreate()
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    viewModel.searchSections.asObservable()
      .bind(to: searchTableView.rx.items(dataSource: searchDataSource))
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
    
    searchTableView.rx.itemSelected
      .do(onNext: { [unowned self] indexPath in
        self.searchTableView.deselectRow(at: indexPath, animated: false)
      })
      .map { [unowned self] indexPath in
        try! self.searchDataSource.model(at: indexPath) as! TaskItem
      }
      .subscribe(viewModel.editAction.inputs)
      .disposed(by: bag)
    
    viewModel.running.asObservable()
      .bind(to: activityIndicator.rx.isAnimating)
      .disposed(by: bag)
    
    viewModel.running.asObservable()
      .map({ (bool) in
        return !bool
      })
      .bind(to: tableView.rx.isUserInteractionEnabled)
      .disposed(by: bag)

    menuButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.menuTap)
      .disposed(by: bag)
    
    searchButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asObservable()
      .subscribe(onNext: { [unowned self] _ in
        self.toggleSearchBar()
      })
      .disposed(by: bag)
    
    viewModel.selectedGroupTitle.asObservable()
      .subscribe(onNext: { [unowned self] name in
        self.title = name
        self.closeSearchBar()
      })
      .disposed(by: bag)
    
    viewModel.searchSections
      .asDriver()
      .drive(onNext: { [unowned self] _ in
        self.searchTableView.frame.size.height = self.searchTableView.contentSize.height
      })
      .disposed(by: bag)
    
    searchBar.rx.text.orEmpty
      .map({ [unowned self] query in
        var due = TaskSection(header: "due tasks", items: [])
        due.items = self.dataSource.sectionModels[0].items.filter{ $0.title.contains(query) }
        var done = TaskSection(header: "done tasks", items: [])
        done.items = self.dataSource.sectionModels[1].items.filter{ $0.title.contains(query) }
        return [due, done]
      })
      .bind(to: viewModel.searchSections)
      .disposed(by: bag)
    
  }
  
  func toggleSearchBar() {
    if blurEffectView.isHidden {
      fadeView(view: blurEffectView, hidden: false)
      fadeView(view: searchBar, hidden: false)
      navigationItem.titleView = searchBar
      searchButton.title = "CANCEL"
      searchBar.becomeFirstResponder()
    } else {
      fadeView(view: blurEffectView, hidden: true)
      fadeView(view: searchBar, hidden: true)
      navigationItem.titleView = nil
      searchButton.title = "SEARCH"
      searchBar.resignFirstResponder()
    }
  }
  
  func fadeView(view: UIView, hidden: Bool) {
    UIView.transition(with: view, duration: 0.5, options: .transitionCrossDissolve, animations: {
      view.isHidden = hidden
    })
  }
  
  func closeSearchBar() {
    blurEffectView.isHidden = true
    searchBar.isHidden = true
    searchButton.title = "SEARCH"
    searchBar.resignFirstResponder()
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
    
    searchDataSource = RxTableViewSectionedReloadDataSource<TaskSection> (
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
