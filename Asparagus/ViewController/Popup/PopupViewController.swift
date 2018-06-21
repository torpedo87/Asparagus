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
  enum LabelMode: String {
    case bug
    case duplicate
    case enhancement
    case goodfirstissue = "good first issue"
    case helpwanted = "help wanted"
    case invalid
    case question
    case wontfix
    static let arr: [LabelMode] = [.bug, .duplicate, .enhancement, .goodfirstissue,
                                   .helpwanted, .invalid, .question, .wontfix]
  }
  
  enum PopupMode: String {
    case Assignees
    case Labels
    case CheckLists
  }
  
  var popupMode: PopupMode!
  private let bag = DisposeBag()
  var viewModel: IssueDetailViewModel!
  
  private lazy var closeButton: UIBarButtonItem = {
    let button = UIBarButtonItem(title: "Close",
                                 style: UIBarButtonItemStyle.plain,
                                 target: self,
                                 action: nil)
    return button
  }()
  private lazy var closeAssigneeButton: UIButton = {
    let button = UIButton()
    button.setTitle("Close", for: .normal)
    button.setTitleColor(.black, for: .normal)
    button.backgroundColor = .white
    button.layer.cornerRadius = 10
    return button
  }()
  private lazy var checkListTableView: UITableView = {
    let view = UITableView()
    view.delegate = self
    view.backgroundColor = UIColor(hex: "232429")
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTaskCell.self, forCellReuseIdentifier: SubTaskCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var tagTableView: UITableView = {
    let view = UITableView()
    view.backgroundColor = UIColor(hex: "232429")
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTagCell.self,
                  forCellReuseIdentifier: SubTagCell.reuseIdentifier)
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
    title = popupMode.rawValue
    navigationItem.rightBarButtonItem = closeButton
    
    switch popupMode as! PopupMode {
    case .CheckLists:
      addContentsView(contentsView: checkListTableView)
    case .Labels:
      addContentsView(contentsView: tagTableView)
    case .Assignees:
      addContentsView(contentsView: assigneeCollectionView)
      view.addSubview(closeAssigneeButton)
      assigneeCollectionView.snp.remakeConstraints { (make) in
        if #available(iOS 11.0, *) {
          make.left.top.right.equalTo(view.safeAreaLayoutGuide).inset(10)
        } else {
          make.left.top.right.equalToSuperview().inset(10)
        }
        make.height.equalTo(UIScreen.main.bounds.height / 6)
      }
      closeAssigneeButton.snp.makeConstraints { (make) in
        if #available(iOS 11.0, *) {
          make.left.bottom.right.equalTo(view.safeAreaLayoutGuide).inset(10)
        } else {
          make.left.bottom.right.equalToSuperview().inset(10)
        }
        make.top.equalTo(assigneeCollectionView.snp.bottom).offset(10)
      }
    }
    
  }
  
  func bindViewModel() {
    closeButton.rx.action = viewModel.popView()
    closeAssigneeButton.rx.action = viewModel.popView()
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
    
    Observable.of(LabelMode.arr)
      .bind(to: tagTableView.rx.items) { [unowned self]
        (tableView: UITableView, index: Int, item: LabelMode) in
        let cell = SubTagCell(style: .default,
                              reuseIdentifier: SubTagCell.reuseIdentifier)
        let tags = self.viewModel.tags().map{ $0.title }
        cell.configureCell(item: LabelMode.arr[index], isTagged: tags.contains(item.rawValue))
        return cell
      }
      .disposed(by: bag)
    
    tagTableView.rx.itemSelected
      .map { [unowned self] indexPath -> (Tag, LocalTaskService.EditMode) in
        let tags = self.viewModel.tags().map{ $0.title }
        let model = LabelMode.arr[indexPath.row]
        let cell = self.tagTableView.cellForRow(at: indexPath) as? SubTagCell
        if tags.contains(model.rawValue) {
          cell?.configureCell(item: model, isTagged: false)
          return (Tag(title: model.rawValue), .delete)
        } else {
          cell?.configureCell(item: model, isTagged: true)
          return (Tag(title: model.rawValue), .add)
        }
      }.bind(to: viewModel.onUpdateTags.inputs)
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: checkListTableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    closeButton.rx.action = viewModel.popView()
  }
  
  func addContentsView(contentsView: UIView) {
    view.addSubview(contentsView)
    contentsView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.edges.equalTo(view.safeAreaLayoutGuide)
      } else {
        make.edges.equalToSuperview()
      }
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

extension PopupViewController: UIPopoverPresentationControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
  }
  
  func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
    return false
  }
}

extension PopupViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView,
                 forSection section: Int) {
    view.tintColor = UIColor(hex: "19263C")
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = .white
  }
}
