//
//  PopupViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 4..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources
import RxKeyboard
import Action

enum PopupMode {
  case assignee
  case label
  case subTask
}

class PopupViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var popupMode: PopupMode!
  var viewModel: IssueDetailViewModel!
  private lazy var customBackButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(title: "X",
                      style: UIBarButtonItemStyle.plain,
                      target: self,
                      action: nil)
    return item
  }()
  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white
    view.layer.cornerRadius = 10
    return view
  }()
  private lazy var closeButton: UIButton = {
    let button = UIButton()
    button.setTitle("Close", for: .normal)
    button.setTitleColor(UIColor.white, for: .normal)
    button.backgroundColor = UIColor.clear
    return button
  }()
  
  private lazy var checkListTableView: UITableView = {
    let view = UITableView()
    view.layer.cornerRadius = 10
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTaskCell.self, forCellReuseIdentifier: SubTaskCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var tagTableView: UITableView = {
    let view = UITableView()
    view.layer.cornerRadius = 10
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTagCell.self,
                  forCellReuseIdentifier: SubTagCell.reuseIdentifier)
    view.register(NewTaskCell.self,
                  forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var assigneeTableView: UITableView = {
    let view = UITableView()
    view.layer.cornerRadius = 10
    view.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
    return view
  }()
  var dataSource: RxTableViewSectionedAnimatedDataSource<SubTaskSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    view.backgroundColor = UIColor.clear
  }
  
  func setupView() {
    view.backgroundColor = UIColor.clear
    view.addSubview(containerView)
    view.addSubview(closeButton)
    
    containerView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.bottom.left.right.equalTo(view)
      }
      make.height.equalTo(UIScreen.main.bounds.height * 2 / 3)
    }
    closeButton.snp.makeConstraints { (make) in
      closeButton.sizeToFit()
      make.right.equalTo(containerView).offset(-10)
      make.bottom.equalTo(containerView.snp.top)
    }
    
    switch popupMode {
    case .subTask:
      addTableView(tableView: checkListTableView)
    case .label:
      addTableView(tableView: tagTableView)
    case .assignee:
      addTableView(tableView: assigneeTableView)
    default: return
    }
  }
  
  func bindViewModel() {
    //로그인상태에서만 assignee 정보 요청하기
    viewModel.isLoggedIn()
      .filter{ return $0 }
      .flatMap({ [unowned self] _ in
        return self.viewModel.repoUsers()
      }).bind(to: assigneeTableView.rx.items) {
        [unowned self] (tableView: UITableView, index: Int, element: User) in
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TableViewCell")
        cell.textLabel?.text = element.name
        let assigneeNameArr = self.viewModel.task.assignees.toArray().map{ $0.name }
        cell.accessoryType = assigneeNameArr.contains(element.name) ? .checkmark : .none
        return cell
      }
      .disposed(by: bag)
    
    assigneeTableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] indexPath in
        self.assigneeTableView.deselectRow(at: indexPath, animated: false)
        if let cell = self.assigneeTableView.cellForRow(at: indexPath) {
          if cell.accessoryType == .checkmark {
            cell.accessoryType = .none
          } else {
            cell.accessoryType = .checkmark
          }
        }
      })
      .disposed(by: bag)
    
    assigneeTableView.rx.modelSelected(User.self)
      .map { [unowned self] user -> (Assignee, LocalTaskService.EditMode) in
        let assignee = Assignee(name: user.name)
        let assigneeNameArr = self.viewModel.task.assignees.toArray().map{ $0.name }
        if assigneeNameArr.contains(user.name) {
          return (assignee, .delete)
        } else {
          return (assignee, .add)
        }
      }
      .debug("------0------------")
      .bind(to: viewModel.onUpdateAssignees.inputs)
      .disposed(by: bag)
    
    viewModel.tags()
      .bind(to: tagTableView.rx.items) { [unowned self]
        (tableView: UITableView, index: Int, item: Tag) in
        if index == 0 {
          let cell = NewTaskCell(style: .default,
                                 reuseIdentifier: NewTaskCell.reuseIdentifier)
          cell.configureNewTagCell(onUpdateTags: self.viewModel.onUpdateTags)
          return cell
        } else {
          let cell = SubTagCell(style: .default,
                                reuseIdentifier: SubTagCell.reuseIdentifier)
          cell.configureCell(item: item,
                             onUpdateTags: self.viewModel.onUpdateTags)
          return cell
        }
      }
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: checkListTableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    closeButton.rx.action = viewModel.popView()
  }
  
  func addTableView(tableView: UITableView) {
    containerView.addSubview(tableView)
    tableView.snp.makeConstraints { (make) in
      make.top.left.right.equalTo(containerView)
      make.bottom.equalTo(containerView).offset(-10)
    }
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedAnimatedDataSource<SubTaskSection>(
      configureCell: { [unowned self] (dataSource, tableView, indexPath, item) in
        switch indexPath.section {
        case 0: do {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: NewTaskCell.reuseIdentifier)
            as? NewTaskCell else { return NewTaskCell() }
          cell.configureCell(onAddTasks: self.viewModel.onAddSubTask)
          return cell
          }
        default: do {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: SubTaskCell.reuseIdentifier)
            as? SubTaskCell else { return TaskCell() }
          cell.configureCell(item: item, action: self.viewModel.onToggle(task: item))
          return cell
          }
        }
      },
      titleForHeaderInSection: { dataSource, sectionIndex in
        return dataSource[sectionIndex].header
    }
    )
  }
}
