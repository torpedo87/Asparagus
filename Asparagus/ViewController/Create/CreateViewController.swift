//
//  CreateViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 5..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

class CreateViewController: UIViewController, BindableType, UIViewControllerTransitioningDelegate {
  private let bag = DisposeBag()
  var viewModel: CreateViewModel!
  private lazy var container: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white
    view.layer.cornerRadius = 10
    view.layer.shadowColor = UIColor.darkGray.cgColor
    view.layer.shadowRadius = 15
    view.layer.shadowOpacity = 0.75
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
  
  private lazy var bodyTextView: UITextView = {
    let view = UITextView()
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    view.text = "Please enter task body"
    view.textColor = UIColor.lightGray
    return view
  }()
  
  private let pickerView: UIPickerView = {
    let view = UIPickerView()
    return view
  }()
  
  private let tagTextField: UITextField = {
    let view = UITextField()
    view.placeholder = "add tag with #"
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    return view
  }()
  
  private var cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("CLOSE", for: .normal)
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    return btn
  }()
  
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("SAVE", for: .normal)
    return btn
  }()
  private lazy var repositoryButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "repository"), for: .normal)
    return btn
  }()
  private lazy var tagButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "tag"), for: .normal)
    return btn
  }()
  private lazy var subTaskButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "list"), for: .normal)
    return btn
  }()
  private lazy var buttonStackView: UIStackView = {
    let view = UIStackView()
    view.axis = .horizontal
    view.spacing = 5
    view.distribution = .fillEqually
    return view
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    titleTextField.becomeFirstResponder()
  }
  
  func setupView() {
    title = "Edit"
    view.addSubview(container)
    container.addSubview(cancelButton)
    container.addSubview(saveButton)
    container.addSubview(titleTextField)
    container.addSubview(bodyTextView)
    buttonStackView.addArrangedSubview(repositoryButton)
    buttonStackView.addArrangedSubview(tagButton)
    buttonStackView.addArrangedSubview(subTaskButton)
    container.addSubview(buttonStackView)
    container.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 3 / 4)
      make.height.equalTo(UIScreen.main.bounds.height / 3)
    }
    cancelButton.snp.makeConstraints { (make) in
      cancelButton.sizeToFit()
      make.left.equalTo(container.snp.left).offset(10)
      make.top.equalTo(container.snp.top).offset(10)
    }
    saveButton.snp.makeConstraints { (make) in
      saveButton.sizeToFit()
      make.top.equalTo(container.snp.top).offset(10)
      make.right.equalTo(container.snp.right).offset(-10)
    }
    titleTextField.snp.makeConstraints { (make) in
      make.left.equalTo(container.snp.left).offset(10)
      make.top.equalTo(cancelButton.snp.bottom).offset(10)
      make.right.equalTo(container.snp.right).offset(-10)
      make.height.equalTo(50)
    }
    bodyTextView.snp.makeConstraints { (make) in
      make.top.equalTo(titleTextField.snp.bottom).offset(10)
      make.left.right.equalTo(titleTextField)
      make.bottom.equalTo(buttonStackView.snp.top).offset(-10)
    }
    buttonStackView.snp.makeConstraints { (make) in
      make.right.equalTo(container.snp.right).offset(-10)
      make.bottom.equalTo(container.snp.bottom).offset(-10)
    }
  }
  
  func bindViewModel() {
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveButton.rx.isEnabled)
      .disposed(by: bag)
    
    bodyTextView.rx.didBeginEditing
      .subscribe(onNext: { [unowned self] _ in
        if self.bodyTextView.textColor == .lightGray {
          self.bodyTextView.text = nil
          self.bodyTextView.textColor = UIColor.black
        }
      })
      .disposed(by: bag)
    
    pickerView.rx.modelSelected(String.self)
      .map { models -> String in
        return models.first!
      }.bind(to: selectedRepositoryLabel.rx.text)
      .disposed(by: bag)
    
    cancelButton.rx.action = viewModel.onCancel
    
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String, String, [String]) in
        let title = self.titleTextField.text ?? ""
        let body = self.bodyTextView.text ?? ""
        let repoName = self.selectedRepositoryLabel.text ?? ""
        let tagText = self.tagTextField.text ?? ""
        let tags = self.viewModel.findAllTagsFromText(tagText: tagText)
        return (title, body, repoName, tags)
      }).bind(to: viewModel.onCreate.inputs)
      .disposed(by: bag)
    
    viewModel.repoTitles
      .bind(to: pickerView.rx.itemTitles) { _, item in
        return "\(item)"
      }
      .disposed(by: bag)
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
  }
}
