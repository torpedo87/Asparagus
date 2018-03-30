//
//  DetailViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 24..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources

class DetailViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: DetailViewModel!
  
  private lazy var container: FoldableView = {
    let view = FoldableView()
    view.backgroundColor = UIColor(hex: "F8F897")
    view.layer.cornerRadius = 10
    view.layer.shadowColor = UIColor.darkGray.cgColor
    view.layer.shadowRadius = 15
    view.layer.shadowOpacity = 0.75
    return view
  }()
  private lazy var segmentedControl: UISegmentedControl = {
    let view = UISegmentedControl(items: ["Repository", "Tags", "CheckList"])
    view.selectedSegmentIndex = 0
    view.backgroundColor = UIColor.white
    view.tintColor = UIColor(hex: "2875A3")
    return view
  }()
  private let pickerView: UIPickerView = {
    let view = UIPickerView()
    return view
  }()
  private lazy var repoView: UIView = {
    let view = UIView()
    return view
  }()
  private let selectedRepositoryLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.backgroundColor = UIColor.white
    return label
  }()
  private lazy var tagTableView: UITableView = {
    let view = UITableView()
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTagCell.self, forCellReuseIdentifier: SubTagCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var checkListTableView: UITableView = {
    let view = UITableView()
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTaskCell.self, forCellReuseIdentifier: SubTaskCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private let titleTextField: UITextField = {
    let view = UITextField()
    view.backgroundColor = UIColor.white
    view.placeholder = "Please enter task title"
    view.layer.cornerRadius = 10
    return view
  }()
  
  private lazy var bodyTextView: UITextView = {
    let view = UITextView()
    view.layer.cornerRadius = 10
    view.text = "Please enter task body"
    view.textColor = UIColor.lightGray
    return view
  }()
  private var backButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitle("BACK", for: .normal)
    return btn
  }()
  private var cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitle("CANCEL", for: .normal)
    return btn
  }()
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("SAVE", for: .normal)
    return btn
  }()
  private var deleteButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("DELETE", for: .normal)
    return btn
  }()
  
  private lazy var expandButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "expand"), for: .normal)
    return btn
  }()
  private lazy var tempView: UIView = {
    let view = UIView()
    view.isHidden = true
    return view
  }()
  var dataSource: RxTableViewSectionedAnimatedDataSource<SubTaskSection>!
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
    titleTextField.becomeFirstResponder()
  }
  
  func setupView() {
    title = "Detail"
    view.backgroundColor = UIColor(hex: "F8F897")
    view.addSubview(backButton)
    view.addSubview(cancelButton)
    view.addSubview(container)
    container.addSubview(saveButton)
    container.addSubview(deleteButton)
    container.addSubview(titleTextField)
    container.addSubview(bodyTextView)
    container.addSubview(tempView)
    tempView.addSubview(segmentedControl)
    tempView.addSubview(repoView)
    repoView.addSubview(selectedRepositoryLabel)
    repoView.addSubview(pickerView)
    tempView.addSubview(tagTableView)
    tempView.addSubview(checkListTableView)
    container.addSubview(expandButton)
    
    backButton.snp.makeConstraints { (make) in
      backButton.sizeToFit()
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(10)
    }
    cancelButton.snp.makeConstraints { (make) in
      backButton.sizeToFit()
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(10)
    }
    container.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 4 / 5)
      make.height.equalTo(UIScreen.main.bounds.height / 3)
    }
    saveButton.snp.makeConstraints { (make) in
      make.width.equalTo(100)
      make.height.equalTo(40)
      make.top.equalTo(container).offset(10)
      make.right.equalTo(container).offset(-10)
    }
    deleteButton.snp.makeConstraints { (make) in
      make.width.equalTo(100)
      make.height.equalTo(40)
      make.top.equalTo(container).offset(10)
      make.left.equalTo(container).offset(10)
    }
    titleTextField.snp.makeConstraints { (make) in
      make.top.equalTo(saveButton.snp.bottom).offset(10)
      make.left.equalTo(container.snp.left).offset(10)
      make.right.equalTo(container.snp.right).offset(-10)
      make.height.equalTo(50)
    }
    bodyTextView.snp.makeConstraints { (make) in
      make.top.equalTo(titleTextField.snp.bottom).offset(10)
      make.left.right.equalTo(titleTextField)
      make.height.equalTo(UIScreen.main.bounds.height / 7)
    }
    tempView.snp.makeConstraints { (make) in
      make.top.equalTo(bodyTextView.snp.bottom).offset(10)
      make.left.right.equalTo(titleTextField)
      make.bottom.equalTo(expandButton.snp.top).offset(-10)
    }
    segmentedControl.snp.makeConstraints { (make) in
      make.left.top.right.equalTo(tempView)
    }
    repoView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(5)
      make.left.bottom.right.equalTo(tempView)
    }
    selectedRepositoryLabel.snp.makeConstraints { (make) in
      make.left.top.right.equalTo(repoView)
    }
    pickerView.snp.makeConstraints { (make) in
      make.top.equalTo(selectedRepositoryLabel.snp.bottom)
      make.left.bottom.right.equalTo(repoView)
    }
    tagTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(5)
      make.left.bottom.right.equalTo(tempView)
    }
    checkListTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(5)
      make.left.bottom.right.equalTo(tempView)
    }
    expandButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(30)
      make.right.equalTo(container).offset(-20)
      make.bottom.equalTo(container).offset(-20)
    }
  }
  
  func toggleSubViews() {
    if tempView.isHidden {
      fadeView(view: tempView, hidden: false)
    } else {
      fadeView(view: tempView, hidden: false)
    }
  }
  
  func toggleTableViews(index: Int) {
    switch index {
    case 0: do {
      fadeView(view: pickerView, hidden: false)
      fadeView(view: tagTableView, hidden: true)
      fadeView(view: checkListTableView, hidden: true)
      }
    case 1: do {
      fadeView(view: pickerView, hidden: true)
      fadeView(view: tagTableView, hidden: false)
      fadeView(view: checkListTableView, hidden: true)
      }
    case 2: do {
      fadeView(view: pickerView, hidden: true)
      fadeView(view: tagTableView, hidden: true)
      fadeView(view: checkListTableView, hidden: false)
      }
    default: do {}
    }
  }
  
  func fadeView(view: UIView, hidden: Bool) {
    UIView.transition(with: view, duration: 0.5, options: [.transitionCrossDissolve], animations: {
      view.isHidden = hidden
    })
  }
  
  func bindViewModel() {
    if viewModel.task.title == "" {
      self.backButton.isHidden = true
      self.deleteButton.isHidden = true
    } else {
      self.cancelButton.isHidden = true
    }
    
    viewModel.tags()
      .bind(to: tagTableView.rx.items) { [unowned self]
        (tableView: UITableView, index: Int, item: Tag) in
        if index == 0 {
          let cell = NewTaskCell(style: .default, reuseIdentifier: NewTaskCell.reuseIdentifier)
          cell.configureNewTagCell(vm: self.viewModel)
          return cell
        } else {
          let cell = SubTagCell(style: .default, reuseIdentifier: SubTagCell.reuseIdentifier)
          cell.configureCell(item: item, vm: self.viewModel)
          return cell
        }
      }
      .disposed(by: bag)
    
    segmentedControl.rx.selectedSegmentIndex.asDriver()
      .drive(onNext: { [unowned self] index in
        self.toggleTableViews(index: index)
      })
      .disposed(by: bag)
    
    expandButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [unowned self] _ in
        self.container.toggle()
        self.toggleSubViews()
      })
      .disposed(by: bag)
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveButton.rx.isEnabled)
      .disposed(by: bag)
    
    titleTextField.text = viewModel.task.title
    bodyTextView.text = viewModel.task.body
    
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String) in
        let title = self.titleTextField.text ?? ""
        let body = self.bodyTextView.text ?? ""
        return (title, body)
      }).bind(to: viewModel.onUpdateTitleBody.inputs)
      .disposed(by: bag)
    
    deleteButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map { [unowned self] _ -> TaskItem in
        return self.viewModel.task
      }.bind(to: viewModel.onDelete.inputs)
      .disposed(by: bag)
    
    cancelButton.rx.tap
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
    
    deleteButton.isEnabled = !viewModel.task.isServerGeneratedType
    
    backButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [unowned self] _ in
        self.viewModel.pop()
      })
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: checkListTableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    viewModel.repoTitles
      .bind(to: pickerView.rx.itemTitles) { _, item in
        return "\(item)"
      }
      .disposed(by: bag)
    
    pickerView.isUserInteractionEnabled = !viewModel.task.isServerGeneratedType
    
    pickerView.rx.modelSelected(String.self)
      .map { models -> String in
        return models.first!
      }.bind(to: selectedRepositoryLabel.rx.text)
      .disposed(by: bag)
    
    if let repo = viewModel.task.repository {
      selectedRepositoryLabel.text = repo.name
    } else {
      selectedRepositoryLabel.text = ""
    }
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedAnimatedDataSource<SubTaskSection>(
      configureCell: { [unowned self] (dataSource, tableView, indexPath, item) in
        switch indexPath.section {
        case 0: do {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: NewTaskCell.reuseIdentifier)
            as? NewTaskCell else { return NewTaskCell() }
          cell.configureCell(vm: self.viewModel)
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
