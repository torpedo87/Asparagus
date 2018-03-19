//
//  EditViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 2..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

class EditViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: EditViewModel!
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
  private let tagLabel: UILabel = {
    let label = UILabel()
    label.text = "Tags with #: "
    return label
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
  
  private var deleteButton: UIButton = {
    let btn = UIButton()
    btn.backgroundColor = UIColor(hex: "FD9727")
    btn.setTitle("DELETE", for: .normal)
    btn.layer.cornerRadius = 10
    return btn
  }()
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.backgroundColor = UIColor(hex: "4054B2")
    btn.layer.cornerRadius = 10
    btn.setTitle("SAVE", for: .normal)
    btn.setTitle("Enter title", for: .disabled)
    return btn
  }()
  
  func bindViewModel() {
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveButton.rx.isEnabled)
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
    
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String, [String]) in
        let title = self.titleTextField.text ?? ""
        let body = self.bodyTextView.text ?? ""
        let tagText = self.tagTextField.text ?? ""
        let tags = self.viewModel.findAllTagsFromText(tagText: tagText)
        return (title, body, tags)
      }).bind(to: viewModel.onUpdate.inputs)
        .disposed(by: bag)
    
    deleteButton.rx.tap
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
    stackView.addArrangedSubview(tagTextField)
    buttonStackView.addArrangedSubview(deleteButton)
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
