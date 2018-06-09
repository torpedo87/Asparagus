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
  
  private lazy var buttonContainerView: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 10
    view.clipsToBounds = true
    return view
  }()
  private lazy var subTaskButton: UIButton = {
    let item = UIButton()
    item.backgroundColor = UIColor(hex: "292D36")
    item.setImage(UIImage(named: "subTask"), for: .normal)
    item.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    item.imageView?.contentMode = .scaleAspectFit
    item.alpha = 0.75
    return item
  }()
  private lazy var labelButton: UIButton = {
    let item = UIButton()
    item.backgroundColor = UIColor(hex: "292D36")
    item.setImage(UIImage(named: "tag"), for: .normal)
    item.imageView?.contentMode = .scaleAspectFit
    item.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    item.alpha = 0.75
    return item
  }()
  private lazy var assigneeButton: UIButton = {
    let item = UIButton()
    item.backgroundColor = UIColor(hex: "292D36")
    item.setImage(UIImage(named: "assignee"), for: .normal)
    item.imageView?.contentMode = .scaleAspectFit
    item.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    item.alpha = 0.75
    return item
  }()
  private lazy var dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.lightGray
    return label
  }()
  
  internal lazy var customBackButton: UIBarButtonItem = {
    let item =
      UIBarButtonItem(title: "BACK",
                      style: UIBarButtonItemStyle.plain,
                      target: self,
                      action: nil)
    return item
  }()
  private lazy var doneButton: UIBarButtonItem = {
    let item = UIBarButtonItem(barButtonSystemItem: .done,
                               target: self,
                               action: nil)
    item.customView?.isHidden = true
    return item
  }()
  private let bag = DisposeBag()
  var viewModel: IssueDetailViewModel!
  
  private lazy var titleTextField: UITextField = {
    let view = UITextField()
    view.font = UIFont.boldSystemFont(ofSize: 35)
    view.adjustsFontSizeToFitWidth = true
    view.placeholder = "Please enter task title"
    return view
  }()
  
  private lazy var bodyTextView: UITextView = {
    let view = UITextView()
    view.font = UIFont.systemFont(ofSize: 20)
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
    print(viewModel.task.labels.toArray().map{ $0.name })
    view.backgroundColor = .white
    setCustomBackButton()
    view.addSubview(dateLabel)
    view.addSubview(titleTextField)
    view.addSubview(bodyTextView)
    view.addSubview(buttonContainerView)
    buttonContainerView.addSubview(assigneeButton)
    buttonContainerView.addSubview(labelButton)
    buttonContainerView.addSubview(subTaskButton)
    
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
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.left.right.bottom.equalTo(view)
      }
      make.top.equalTo(titleTextField.snp.bottom).offset(8)
    }
    buttonContainerView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.bottom.equalToSuperview().offset(-50)
      make.width.equalTo(UIScreen.main.bounds.width / 2)
      make.height.equalTo(UIScreen.main.bounds.height / 15)
    }
    labelButton.snp.makeConstraints { (make) in
      make.left.bottom.top.equalTo(buttonContainerView)
      make.width.equalTo(UIScreen.main.bounds.width / 6)
    }
    assigneeButton.snp.makeConstraints { (make) in
      make.bottom.top.equalTo(buttonContainerView)
      make.left.equalTo(labelButton.snp.right)
      make.width.equalTo(labelButton)
    }
    subTaskButton.snp.makeConstraints { (make) in
      make.right.bottom.top.equalTo(buttonContainerView)
      make.width.equalTo(labelButton)
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
    doneButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
    
    customBackButton.rx.action = viewModel.onCancel
    subTaskButton.rx.action = viewModel.popup(mode: .subTask)
    assigneeButton.rx.action = viewModel.popup(mode: .assignee)
    labelButton.rx.action = viewModel.popup(mode: .label)
    
    viewModel.isLoggedIn()
      .bind(to: assigneeButton.rx.isEnabled)
      .disposed(by: bag)
    
    RxKeyboard.instance.visibleHeight
      .drive(onNext: { [unowned self] keyboardVisibleHeight in
        var actualKeyboardHeight = keyboardVisibleHeight
        if keyboardVisibleHeight == 0 {
          self.navigationItem.rightBarButtonItem = nil
        } else {
          self.navigationItem.rightBarButtonItem = self.doneButton
        }
        if #available(iOS 11.0, *), keyboardVisibleHeight > 0 {
          actualKeyboardHeight = actualKeyboardHeight - self.view.safeAreaInsets.bottom
        }
        self.view.setNeedsLayout()
      })
      .disposed(by: bag)

    RxKeyboard.instance.willShowVisibleHeight
      .drive(onNext: { [unowned self] keyboardVisibleHeight in
        self.bodyTextView.contentOffset.y += keyboardVisibleHeight
      })
      .disposed(by: bag)
    
  }
}

