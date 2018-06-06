//
//  IssueDetailViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 3..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources
import RxKeyboard

class IssueDetailViewController: UIViewController, BindableType, GoBackable {
  private lazy var toolbar: UIToolbar = {
    let bar = UIToolbar()
    return bar
  }()
  private lazy var dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.lightGray
    return label
  }()
  private lazy var subTaskBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(title: "SubTask", style: .plain, target: self, action: nil)
    return item
  }()
  private lazy var labelBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(title: "Label", style: .plain, target: self, action: nil)
    return item
  }()
  private lazy var assigneeBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(title: "Assignee", style: .plain, target: self, action: nil)
    return item
  }()
  internal lazy var customBackButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(title: "BACK",
                      style: UIBarButtonItemStyle.plain,
                      target: self,
                      action: nil)
    return item
  }()
  private let bag = DisposeBag()
  var viewModel: IssueDetailViewModel!
  
  private let titleTextField: UITextField = {
    let view = UITextField()
    view.adjustsFontSizeToFitWidth = true
    view.placeholder = "Please enter task title"
    return view
  }()
  
  private lazy var bodyTextView: UITextView = {
    let view = UITextView()
    view.layer.borderWidth = 0.5
    view.layer.borderColor = UIColor(hex: "DBD9DB").cgColor
    return view
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if #available(iOS 11.0, *) {
      self.navigationController?.navigationBar.prefersLargeTitles = false
    } else {
      // Fallback on earlier versions
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if #available(iOS 11.0, *) {
      self.navigationController?.navigationBar.prefersLargeTitles = true
    } else {
      // Fallback on earlier versions
    }
  }
  
  func setupView() {
    
    setCustomBackButton()
    view.addSubview(dateLabel)
    view.addSubview(titleTextField)
    view.addSubview(bodyTextView)
    view.addSubview(toolbar)
    let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    toolbar.items = [assigneeBarButtonItem, flexible, labelBarButtonItem, flexible, subTaskBarButtonItem]
    toolbar.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.bottom.left.right.equalTo(view)
      }
      make.height.equalTo(44)
    }
    dateLabel.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      } else {
        make.top.equalTo(view)
      }
      dateLabel.sizeToFit()
      make.centerX.equalToSuperview()
    }
    titleTextField.snp.makeConstraints({ (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      } else {
        make.left.right.equalTo(view)
      }
      make.top.equalTo(dateLabel.snp.bottom).offset(8)
      make.height.equalTo(44)
    })
    
    bodyTextView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      } else {
        make.left.right.equalTo(view)
      }
      make.top.equalTo(titleTextField.snp.bottom).offset(8)
      make.bottom.equalTo(toolbar.snp.top)
    }
  }
  
  func bindViewModel() {
    dateLabel.text = viewModel.task.updated
    titleTextField.text = viewModel.task.title
    bodyTextView.text = viewModel.task.body
    
    //title, body 변경시 자동 저장
    Observable.combineLatest(titleTextField.rx.text.orEmpty,
                             bodyTextView.rx.text.orEmpty)
      .debounce(0.5, scheduler: MainScheduler.instance)
      .skip(1)
      .filter({ tuple -> Bool in
        return !tuple.0.isEmpty
      })
      .bind(to: viewModel.onUpdateTitleBody.inputs)
      .disposed(by: bag)
    
    
    //화면 탭시 키보드 내리기
    view.rx.tapGesture()
      .skip(1)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
    
    customBackButton.rx.action = viewModel.onCancel
    subTaskBarButtonItem.rx.action = viewModel.popup(mode: .subTask)
    assigneeBarButtonItem.rx.action = viewModel.popup(mode: .assignee)
    labelBarButtonItem.rx.action = viewModel.popup(mode: .label)
    
    viewModel.isLoggedIn()
      .bind(to: assigneeBarButtonItem.rx.isEnabled)
      .disposed(by: bag)
  }
}

