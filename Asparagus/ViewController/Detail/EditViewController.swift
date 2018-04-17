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
  private var assigneeButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "283A45"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("assignee", for: .normal)
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
    view.addSubview(assigneeButton)
    view.addSubview(topView)
    topView.addSubview(titleTextField)
    topView.addSubview(bodyTextView)
    view.addSubview(bottomView)
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
    assigneeButton.snp.makeConstraints { (make) in
      make.width.equalTo(100)
      make.height.equalTo(40)
      make.centerX.equalToSuperview()
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
      } else {
        make.top.equalTo(view).offset(10)
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

    checkListTableView.snp.makeConstraints { (make) in
      make.top.bottom.equalTo(bottomView)
      make.left.right.equalTo(bodyTextView)
    }

  }

  func bindViewModel() {
    assigneeButton.rx.action = viewModel.goToPopUpScene()
    
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
      .filter({ [unowned self] _ -> Bool in
        return self.viewModel.selectedRepoTitle.value != ""
      })
      .map { [unowned self] _ -> Repository? in
        return self.viewModel.getRepo(repoName: self.viewModel.selectedRepoTitle.value)
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
