//
//  EditViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 2..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources

class EditViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: EditViewModel!
  
  private let tableView: UITableView = {
    let view = UITableView(frame: CGRect.zero, style: .grouped)
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
    view.sectionHeaderHeight = UIScreen.main.bounds.height / 30
    return view
  }()
  private let selectedRepositoryLabel: UILabel = {
    let label = UILabel()
    return label
  }()
  private let titleTextField: UITextField = {
    let view = UITextField()
    view.placeholder = "Please enter task title"
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    return view
  }()
  
  private let bodyTextView: UITextView = {
    let view = UITextView()
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    return view
  }()
  
  private let tagTextField: UITextField = {
    let view = UITextField()
    view.placeholder = "add tag with #"
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    return view
  }()
  
  private let buttonStackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 10
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
  }()
  
  private lazy var deleteBarButton: UIBarButtonItem = {
    let item = UIBarButtonItem(barButtonSystemItem: .trash,
                               target: self,
                               action: nil)
    return item
  }()
  private lazy var saveBarButton: UIBarButtonItem = {
    let item = UIBarButtonItem(barButtonSystemItem: .save,
                               target: self,
                               action: nil)
    return item
  }()
  private var addSubTaskButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("Add", for: .normal)
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    return btn
  }()
  
  //var dataSource: RxTableViewSectionedReloadDataSource<TotalSection>!
  
  func bindViewModel() {
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveBarButton.rx.isEnabled)
      .disposed(by: bag)
    
    titleTextField.text = viewModel.task.title
    bodyTextView.text = viewModel.task.body
    tagTextField.text = viewModel.task.tag.toArray()
      .map{ $0.title }
      .reduce("", { (tags, tag) -> String in
        return tags + "#\(tag)"
    })
    if let repo = viewModel.task.repository {
      selectedRepositoryLabel.text = repo.name
    } else {
      selectedRepositoryLabel.text = ""
    }
    
    saveBarButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String, [String]) in
        let title = self.titleTextField.text ?? ""
        let body = self.bodyTextView.text ?? ""
        let tagText = self.tagTextField.text ?? ""
        let tags = self.viewModel.findAllTagsFromText(tagText: tagText)
        return (title, body, tags)
      }).bind(to: viewModel.onUpdate.inputs)
        .disposed(by: bag)
    
    deleteBarButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map { [unowned self] _ -> TaskItem in
        return self.viewModel.task
      }.bind(to: viewModel.onDelete.inputs)
      .disposed(by: bag)
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
    
    deleteBarButton.isEnabled = !viewModel.task.isServerGeneratedType
    
//    viewModel.sectionedItems
//      .bind(to: tableView.rx.items(dataSource: dataSource))
//      .disposed(by: bag)
    
    addSubTaskButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        self.viewModel.addSubTask()
      })
      .disposed(by: bag)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    tableView.delegate = self
    configureDataSource()
    titleTextField.becomeFirstResponder()
  }
  
  func setupView() {
    title = "Edit"
    view.backgroundColor = UIColor.white
    navigationItem.rightBarButtonItem = deleteBarButton
    view.addSubview(tableView)

    tableView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
    }
  }
  
  func configureDataSource() {
//    dataSource = RxTableViewSectionedReloadDataSource<TotalSection>(
//      configureCell: { [unowned self] (dataSource, tableView, indexPath, item) in
//        switch item {
//        case .text(_):
//          switch (indexPath.section) {
//          case 0:
//            let cell = tableView.dequeueReusableCell(withIdentifier: CustomCell.reuseIdentifier) as! CustomCell
//            cell.configureCell(customView: self.titleTextField)
//            return cell
//          case 1:
//            let cell = tableView.dequeueReusableCell(withIdentifier: CustomCell.reuseIdentifier) as! CustomCell
//            cell.configureCell(customView: self.bodyTextView)
//            return cell
//          case 2:
//            let cell = tableView.dequeueReusableCell(withIdentifier: CustomCell.reuseIdentifier) as! CustomCell
//            cell.configureCell(customView: self.selectedRepositoryLabel)
//            return cell
//          case 3:
//            let cell = tableView.dequeueReusableCell(withIdentifier: CustomCell.reuseIdentifier) as! CustomCell
//            cell.configureCell(customView: self.tagTextField)
//            return cell
//          default:
//            return UITableViewCell()
//          }
//        case .subTask(let task):
//          guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier)
//            as? TaskCell else { return TaskCell() }
//          cell.configureCell(item: task, action: self.viewModel.onToggle(task: task))
//          return cell
//        }
//    },
//      titleForHeaderInSection: { dataSource, sectionIndex in
//        return dataSource[sectionIndex].header
//    }
//    )
  }
}

extension EditViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
    if section == 4 {
      header.addSubview(addSubTaskButton)
      addSubTaskButton.snp.makeConstraints({ (make) in
        addSubTaskButton.sizeToFit()
        make.right.equalTo(header).offset(-10)
        make.centerY.equalTo(header)
      })
    }
  }
}
