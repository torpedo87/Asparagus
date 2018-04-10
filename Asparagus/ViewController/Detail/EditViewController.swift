//
//  EditViewController.swift
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
import RxKeyboard

class EditViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: EditViewModel!
  private lazy var topView: UIView = {
    let view = UIView()
    return view
  }()
  private lazy var segmentedControl: UISegmentedControl = {
    let view = UISegmentedControl(items: ["Github", "Tags", "Sub-Tasks"])
    view.selectedSegmentIndex = 0
    view.layer.cornerRadius = 10
    view.backgroundColor = UIColor.white
    view.tintColor = UIColor(hex: "283A45")
    return view
  }()
  private let pickerView: UIPickerView = {
    let view = UIPickerView()
    return view
  }()
  private lazy var repoView: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 10
    return view
  }()
  private lazy var repoLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.layer.cornerRadius = 10
    label.backgroundColor = UIColor.white
    label.text = "Repository :"
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  private lazy var selectedRepositoryLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.layer.cornerRadius = 10
    label.backgroundColor = UIColor.white
    return label
  }()
  private lazy var tagTableView: UITableView = {
    let view = UITableView()
    view.layer.cornerRadius = 10
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTagCell.self, forCellReuseIdentifier: SubTagCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var checkListTableView: UITableView = {
    let view = UITableView()
    view.layer.cornerRadius = 10
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTaskCell.self, forCellReuseIdentifier: SubTaskCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private let titleTextField: UITextField = {
    let view = UITextField()
    view.backgroundColor = UIColor.white
    view.placeholder = "Please enter task title"
    view.font = .systemFont(ofSize: 20)
    view.layer.cornerRadius = 10
    return view
  }()
  
  private lazy var bodyTextView: UITextView = {
    let view = UITextView()
    view.layer.cornerRadius = 10
    view.font = .systemFont(ofSize: 20)
    return view
  }()
  
  private var cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "283A45"), for: .normal)
    btn.setTitle("CLOSE", for: .normal)
    return btn
  }()
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "283A45"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("SAVE", for: .normal)
    return btn
  }()
  
  private lazy var bottomView: UIView = {
    let view = UIView()
    return view
  }()
  var dataSource: RxTableViewSectionedAnimatedDataSource<SubTaskSection>!
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setNavigationBarHidden(true, animated: animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.setNavigationBarHidden(false, animated: animated)
  }
  
  func setupView() {
    view.backgroundColor = UIColor(hex: "F5F5F5")
    view.addSubview(cancelButton)
    view.addSubview(saveButton)
    view.addSubview(topView)
    topView.addSubview(titleTextField)
    topView.addSubview(bodyTextView)
    view.addSubview(bottomView)
    bottomView.addSubview(segmentedControl)
    bottomView.addSubview(repoView)
    repoView.addSubview(repoLabel)
    repoView.addSubview(selectedRepositoryLabel)
    repoView.addSubview(pickerView)
    bottomView.addSubview(tagTableView)
    bottomView.addSubview(checkListTableView)
    
    cancelButton.snp.makeConstraints { (make) in
      make.width.equalTo(100)
      make.height.equalTo(40)
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(10)
      } else {
        make.top.left.equalTo(view).offset(10)
      }
    }
    saveButton.snp.makeConstraints { (make) in
      make.width.equalTo(100)
      make.height.equalTo(40)
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-10)
      } else {
        make.top.equalTo(view).offset(10)
        make.right.equalTo(view).offset(-10)
      }
    }
    topView.snp.makeConstraints { (make) in
      make.top.equalTo(saveButton.snp.bottom)
      make.height.equalTo(UIScreen.main.bounds.height / 3)
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      } else {
        make.left.right.equalTo(view)
      }
    }
    
    titleTextField.snp.makeConstraints { (make) in
      make.top.left.equalTo(topView).offset(20)
      make.right.equalTo(topView).offset(-20)
      make.height.equalTo(UIScreen.main.bounds.height / 20)
    }
    bodyTextView.snp.makeConstraints { (make) in
      make.top.equalTo(titleTextField.snp.bottom).offset(20)
      make.left.right.equalTo(titleTextField)
      make.bottom.equalTo(topView)
    }
    
    bottomView.snp.makeConstraints { (make) in
      make.top.equalTo(topView.snp.bottom)
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.left.right.bottom.equalTo(view)
      }
    }
    segmentedControl.snp.makeConstraints { (make) in
      make.top.equalTo(bottomView).offset(20)
      make.left.equalTo(bottomView).offset(20)
      make.right.equalTo(bottomView).offset(-20)
      make.height.equalTo(UIScreen.main.bounds.height / 20)
    }
    repoView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(20)
      make.left.right.equalTo(segmentedControl)
      make.bottom.equalTo(bottomView)
    }
    tagTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(20)
      make.left.right.equalTo(segmentedControl)
      make.bottom.equalTo(bottomView)
    }
    checkListTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(20)
      make.left.right.equalTo(segmentedControl)
      make.bottom.equalTo(bottomView)
    }
    repoLabel.snp.makeConstraints { (make) in
      make.top.left.equalTo(repoView)
      make.height.equalTo(UIScreen.main.bounds.height / 20)
      make.width.equalTo(UIScreen.main.bounds.width / 3)
    }
    selectedRepositoryLabel.snp.makeConstraints { (make) in
      make.left.equalTo(repoLabel.snp.right)
      make.top.right.equalTo(repoView)
      make.height.equalTo(UIScreen.main.bounds.height / 20)
    }
    pickerView.snp.makeConstraints { (make) in
      make.top.equalTo(selectedRepositoryLabel.snp.bottom)
      make.left.right.bottom.equalTo(repoView)
    }
  }
  
  func switchTableViews(index: Int) {
    switch index {
    case 0: do {
      fadeView(view: repoView, hidden: false)
      fadeView(view: tagTableView, hidden: true)
      fadeView(view: checkListTableView, hidden: true)
      }
    case 1: do {
      fadeView(view: repoView, hidden: true)
      fadeView(view: tagTableView, hidden: false)
      fadeView(view: checkListTableView, hidden: true)
      }
    case 2: do {
      fadeView(view: repoView, hidden: true)
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
    RxKeyboard.instance.visibleHeight
      .skip(1)
      .filter{ $0 == 0}
      .drive(onNext: { [unowned self] _ in
        UIView.animate(withDuration: 1.0) {
          self.topView.snp.updateConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.height * 1 / 3)
          }
          self.view.layoutIfNeeded()
        }
      })
      .disposed(by: bag)
    
    RxKeyboard.instance.willShowVisibleHeight
      .drive(onNext: { [unowned self] _ in
        UIView.animate(withDuration: 1.0) {
          self.topView.snp.updateConstraints { make in
            make.height.equalTo(UIScreen.main.bounds.height * 1 / 4)
          }
          self.view.layoutIfNeeded()
        }
      })
      .disposed(by: bag)
    
    cancelButton.rx.action = viewModel.onCancel
    
    viewModel.tags()
      .bind(to: tagTableView.rx.items) { [unowned self]
        (tableView: UITableView, index: Int, item: Tag) in
        if index == 0 {
          let cell = NewTaskCell(style: .default, reuseIdentifier: NewTaskCell.reuseIdentifier)
          cell.configureNewTagCell(onUpdateTags: self.viewModel.onUpdateTags)
          return cell
        } else {
          let cell = SubTagCell(style: .default, reuseIdentifier: SubTagCell.reuseIdentifier)
          cell.configureCell(item: item, onUpdateTags: self.viewModel.onUpdateTags)
          return cell
        }
      }
      .disposed(by: bag)
    
    segmentedControl.rx.selectedSegmentIndex.asDriver()
      .drive(onNext: { [unowned self] index in
        self.switchTableViews(index: index)
      })
      .disposed(by: bag)
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveButton.rx.isEnabled)
      .disposed(by: bag)
    
    titleTextField.text = viewModel.task.title
    bodyTextView.text = viewModel.task.body
    
    Observable.combineLatest(titleTextField.rx.text.orEmpty,
                             bodyTextView.rx.text.orEmpty)
      .debounce(0.5, scheduler: MainScheduler.instance)
      .bind(to: viewModel.onUpdateTitleBody.inputs)
      .disposed(by: bag)
    
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map { [unowned self] _ -> Repository? in
        return self.viewModel.getRepo(repoName: self.selectedRepositoryLabel.text!)
      }
      .bind(to: viewModel.onUpdateRepo.inputs)
      .disposed(by: bag)
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
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
    
    pickerView.isHidden = viewModel.task.isServerGeneratedType

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
