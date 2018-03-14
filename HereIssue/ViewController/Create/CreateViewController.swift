//
//  CreateViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 5..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CreateViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: CreateViewModel!
  private let stackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Title"
    return label
  }()
  
  private let bodyLabel: UILabel = {
    let label = UILabel()
    label.text = "Body"
    return label
  }()
  private let repoLabelStackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 10
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
  }()
  private let repositoryLabel: UILabel = {
    let label = UILabel()
    label.text = "Repository : "
    return label
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
  
  private let pickerView: UIPickerView = {
    let view = UIPickerView()
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
  
  private var cancelButton: UIButton = {
    let btn = UIButton()
    btn.backgroundColor = UIColor.yellow
    btn.setTitle("CANCEL", for: .normal)
    return btn
  }()
  
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.backgroundColor = UIColor.red
    btn.setTitle("SAVE", for: .normal)
    btn.setTitle("enter full", for: .disabled)
    return btn
  }()
  
  func bindViewModel() {
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveButton.rx.isEnabled)
      .disposed(by: bag)
    
    pickerView.rx.modelSelected(String.self)
      .map { models -> String in
        return models.first!
      }.bind(to: selectedRepositoryLabel.rx.text)
      .disposed(by: bag)
    
    cancelButton.rx.action = viewModel.onCancel
    
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String, String) in
        let title = self.titleTextField.text ?? ""
        let body = self.bodyTextView.text ?? ""
        let repoName = self.selectedRepositoryLabel.text ?? ""
        return (title, body, repoName)
      }).bind(to: viewModel.onCreate.inputs)
      .disposed(by: bag)
    
    viewModel.repoTitles
      .bind(to: pickerView.rx.itemTitles) { _, item in
        return "\(item)"
      }
      .disposed(by: bag)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    titleTextField.becomeFirstResponder()
  }
  
  func setupView() {
    title = "Edit"
    view.backgroundColor = UIColor.white
    view.addSubview(stackView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(titleTextField)
    stackView.addArrangedSubview(bodyLabel)
    stackView.addArrangedSubview(bodyTextView)
    repoLabelStackView.addArrangedSubview(repositoryLabel)
    repoLabelStackView.addArrangedSubview(selectedRepositoryLabel)
    
    stackView.addArrangedSubview(repoLabelStackView)
    stackView.addArrangedSubview(pickerView)
    buttonStackView.addArrangedSubview(cancelButton)
    buttonStackView.addArrangedSubview(saveButton)
    stackView.addArrangedSubview(buttonStackView)
    
    stackView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(10)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-10)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
    }
  }
}
