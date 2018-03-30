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
  let transition = PopAnimator()
  private weak var selectedCell: TaskCell?
  private let bag = DisposeBag()
  var viewModel: TaskViewModel!
  
  private lazy var topView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.clear
    return view
  }()
  private lazy var topLabel: UILabel = {
    let view = UILabel()
    view.textAlignment = .center
    return view
  }()
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.register(TaskCell.self,
                  forCellReuseIdentifier: TaskCell.reuseIdentifier)
    view.rowHeight = UIScreen.main.bounds.height / 8
    view.backgroundColor = UIColor.clear
    view.separatorStyle = .none
    view.delegate = self
    return view
  }()
  
  lazy var menuButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "menu"), for: .normal)
    return btn
  }()
  
  lazy var newTaskButton: PlusButton = {
    let btn = PlusButton()
    return btn
  }()
  private let activityIndicator: UIActivityIndicatorView = {
    let spinner = UIActivityIndicatorView()
    spinner.color = UIColor.blue
    spinner.isHidden = false
    return spinner
  }()
  
  var dataSource: RxTableViewSectionedAnimatedDataSource<TaskSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
    
    transition.dismissCompletion = {
      self.newTaskButton.isHidden = false
    }
  }
  
  func setupView() {
    title = "Task"
    view.addSubview(topView)
    topView.addSubview(topLabel)
    topView.addSubview(menuButton)
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
    view.addSubview(newTaskButton)
    
    topView.snp.makeConstraints { (make) in
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.height.equalTo(45)
    }
    topLabel.snp.makeConstraints { (make) in
      make.width.equalTo(200)
      make.center.top.bottom.equalTo(topView)
    }
    menuButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(40)
      make.left.equalTo(topView).offset(10)
      make.centerY.equalTo(topView)
    }
    
    tableView.snp.makeConstraints({ (make) in
      make.top.equalTo(topView.snp.bottom)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
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
    
  }
  
  func bindViewModel() {
    viewModel.selectedGroupTitle
      .bind(to: topLabel.rx.text)
      .disposed(by: bag)
    
    newTaskButton.rx.action = viewModel.onCreateTask()
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .do(onNext: { [unowned self] indexPath in
        self.tableView.deselectRow(at: indexPath, animated: false)
        self.selectedCell = self.tableView.cellForRow(at: indexPath) as! TaskCell
      })
      .map { [unowned self] indexPath in
        try! self.dataSource.model(at: indexPath) as! TaskItem
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
    
    viewModel.selectedGroupTitle.asObservable()
      .subscribe(onNext: { [unowned self] name in
        self.title = name
      })
      .disposed(by: bag)
    
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
  }
}

extension TaskViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

    //push
    if fromVC is TaskViewController, toVC is DetailViewController {
      guard let selectedCell = selectedCell else { fatalError() }
      transition.originFrame = selectedCell.convert(selectedCell.bounds, to: nil)
      transition.presenting = true
      return transition
    }
      //pop
    else if fromVC is DetailViewController, toVC is TaskViewController {
      transition.presenting = false
      return transition
    }
    return nil
  }

}

extension TaskViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = UIColor.clear
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor(hex: "4478E4")
  }
}
