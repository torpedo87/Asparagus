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
    view.backgroundColor = UIColor.clear
    view.delegate = self
    
    //dynamic cell height
    view.rowHeight = UITableViewAutomaticDimension
    view.estimatedRowHeight = 140
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
  private lazy var menuButton: UIBarButtonItem = {
    let btn = UIBarButtonItem(image: UIImage(named: "menu"),
                              style: UIBarButtonItemStyle.plain,
                              target: self,
                              action: nil)
    return btn
  }()
  private lazy var newTaskButton: PlusButton = {
    let btn = PlusButton()
    return btn
  }()
  private lazy var activityIndicator: UIActivityIndicatorView = {
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
    //dynamic cell height
    view.rowHeight = UITableViewAutomaticDimension
    view.estimatedRowHeight = 140
    view.backgroundColor = UIColor.clear
    view.delegate = self
    return view
  }()
  
  private lazy var searchBar: UISearchBar = {
    let bar = UISearchBar()
    bar.isHidden = true
    return bar
  }()
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TaskSection>!
  var searchDataSource: RxTableViewSectionedReloadDataSource<TaskSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
    viewModel.selectedItemSubject.onNext(.inbox("Inbox"))
  }
  
  func setupView() {
    navigationItem.leftBarButtonItem = menuButton
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
    view.addSubview(newTaskButton)
    view.addSubview(blurEffectView)
    blurEffectView.contentView.addSubview(searchTableView)
    navigationItem.rightBarButtonItem = searchButton
    navigationItem.titleView = self.searchBar
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
    activityIndicator.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 10)
      make.center.equalToSuperview()
    }
    newTaskButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(50)
      if #available(iOS 11.0, *) {
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-10)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
      } else {
        make.right.bottom.equalTo(view).offset(-10)
      }
    }
    blurEffectView.snp.makeConstraints { (make) in
      make.edges.equalTo(tableView)
    }
    searchBar.sizeToFit()
    searchTableView.snp.makeConstraints { (make) in
      make.left.top.right.bottom.equalTo(blurEffectView.contentView)
    }
    
  }
  
  func bindViewModel() {
    
    newTaskButton.rx.action = viewModel.onCreateTask()
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    viewModel.searchSections.asObservable()
      .bind(to: searchTableView.rx.items(dataSource: searchDataSource))
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
    
    searchButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asObservable()
      .subscribe(onNext: { [unowned self] _ in
        self.toggleSearchBar()
      })
      .disposed(by: bag)
    
    searchBar.rx.text.orEmpty
      .skip(1)
      .debounce(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] query in
        var dueSection = TaskSection(header: "Due Tasks", items: [])
        dueSection.items = self.dataSource.sectionModels[0].items.filter{ $0.title.contains(query) }
        var doneSection = TaskSection(header: "Done Tasks", items: [])
        doneSection.items = self.dataSource.sectionModels[1].items.filter{ $0.title.contains(query) }
        return [dueSection, doneSection]
      })
      .bind(to: viewModel.searchSections)
      .disposed(by: bag)

    tableView.rx.modelSelected(TaskItem.self)
      .bind(to: viewModel.editAction.inputs)
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] indexPath in
        self.tableView.deselectRow(at: indexPath, animated: false)
      })
      .disposed(by: bag)
    
    let running = viewModel.running.asObservable().share()
    
    running
      .bind(to: activityIndicator.rx.isAnimating)
      .disposed(by: bag)
    
    running
      .bind(to: tableView.rx.isHidden)
      .disposed(by: bag)

    menuButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: ())
      .drive(viewModel.menuTap)
      .disposed(by: bag)
  }
  
  func toggleSearchBar() {
    if blurEffectView.isHidden {
      blurEffectView.isHidden = false
      searchBar.isHidden = false
      searchButton.title = "CANCEL"
      searchBar.becomeFirstResponder()
    } else {
      blurEffectView.isHidden = true
      searchBar.isHidden = true
      searchButton.title = "SEARCH"
      searchBar.resignFirstResponder()
    }
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedAnimatedDataSource<TaskSection> (
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

extension TaskViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = UIColor.white
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor(hex: "2E3136")
  }
}
