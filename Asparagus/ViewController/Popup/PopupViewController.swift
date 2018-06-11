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
import RxDataSources
import Action

class PopupViewController: UIViewController, BindableType {
  
  enum PopupMode {
    case assignee
    case label
    case subTask
  }
  
  var popupMode: PopupMode!
  private let bag = DisposeBag()
  var viewModel: IssueDetailViewModel!
  lazy var containerView: UIView = {
    let view = UIView()
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
  lazy var customLayout: UICollectionViewFlowLayout = {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: UIScreen.main.bounds.height / 6, height: UIScreen.main.bounds.height / 6)
    layout.scrollDirection = UICollectionViewScrollDirection.horizontal
    return layout
  }()
  private lazy var assigneeCollectionView: UICollectionView = {
    let view = UICollectionView(frame: CGRect.zero,
                                collectionViewLayout: customLayout)
    view.layer.cornerRadius = 10
    view.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    view.backgroundColor = .white
    view.register(CarouselCell.self, forCellWithReuseIdentifier: CarouselCell.reuseIdentifier)
    return view
  }()
  var dataSource: RxTableViewSectionedAnimatedDataSource<SubTaskSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    view.backgroundColor = .clear
    view.addSubview(containerView)
    view.addSubview(closeButton)
    
    containerView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left).inset(10)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(10)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
      } else {
        make.left.right.equalTo(view).inset(10)
        make.bottom.equalTo(view).inset(10)
        make.top.equalTo(view).offset(50)
      }
    }
    closeButton.snp.makeConstraints { (make) in
      closeButton.sizeToFit()
      make.right.equalTo(containerView).offset(-10)
      make.bottom.equalTo(containerView.snp.top)
    }
    
    switch popupMode as! PopupMode {
    case .subTask:
      addContentsView(contentsView: checkListTableView)
    case .label:
      addContentsView(contentsView: tagTableView)
    case .assignee:
      addContentsView(contentsView: assigneeCollectionView)
    }
    
  }
  
  func bindViewModel() {
    viewModel.isLoggedIn()
      .filter{ return $0 }
      .flatMap({ [unowned self] _ in
        return self.viewModel.repoUsers()
      }).bind(to: assigneeCollectionView.rx.items) { [unowned self]
        (collectionView: UICollectionView, index: Int, item: User) in
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCell.reuseIdentifier,
                                                         for: IndexPath(item: index, section: 0)) as? CarouselCell {
          let assigneeNames = self.viewModel.task.assignees.toArray().map{ $0.name }
          cell.configCell(item: item, isAssigned: assigneeNames.contains(item.name))
          return cell
        }
        return CarouselCell()
      }
      .disposed(by: bag)
    
    assigneeCollectionView.rx.modelSelected(User.self)
      .map { [unowned self] user -> (Assignee, LocalTaskService.EditMode) in
        let assignee = Assignee(name: user.name)
        let assigneeNameArr = self.viewModel.task.assignees.toArray().map{ $0.name }
        if assigneeNameArr.contains(user.name) {
          return (assignee, .delete)
        } else {
          return (assignee, .add)
        }
      }
      .bind(to: viewModel.onUpdateAssignees.inputs)
      .disposed(by: bag)
    
    assigneeCollectionView.rx.itemSelected
      .asDriver()
      .debug("-----")
      .drive(onNext: { [unowned self] indexPath in
        if let cell = self.assigneeCollectionView.cellForItem(at: indexPath) as? CarouselCell {
          cell.toggleCheck()
        }
      })
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
  
  func addContentsView(contentsView: UIView) {
    containerView.addSubview(contentsView)
    contentsView.snp.makeConstraints { (make) in
      make.top.left.right.equalTo(containerView)
      make.bottom.equalTo(containerView)
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
