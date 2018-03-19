//
//  AuthViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

class AuthViewController: UIViewController, BindableType {
  var viewModel: AuthViewModel!
  private let bag = DisposeBag()
  private var cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("CANCEL", for: .normal)
    btn.setTitleColor(UIColor.blue, for: .normal)
    return btn
  }()
  private let imgView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage(named: "ItemChecked")
    view.contentMode = .scaleAspectFill
    return view
  }()
  private let stackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
  }()
  private let idTextField: UITextField = {
    let txtField = UITextField()
    txtField.placeholder = "Please enter your GitHub ID"
    txtField.layer.borderColor = UIColor.blue.cgColor
    txtField.layer.borderWidth = 0.5
    return txtField
  }()
  private let passWordTextField: UITextField = {
    let txtField = UITextField()
    txtField.placeholder = "Please enter your password"
    txtField.layer.borderColor = UIColor.blue.cgColor
    txtField.isSecureTextEntry = true
    txtField.layer.borderWidth = 0.5
    return txtField
  }()
  private var authButton: UIButton = {
    let btn = UIButton()
    btn.isEnabled = false
    btn.setTitleColor(UIColor.blue, for: .normal)
    btn.setTitleColor(UIColor.gray, for: .disabled)
    return btn
  }()
  private var forgotPasswordButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("Forget your password?", for: .normal)
    btn.setTitleColor(UIColor.blue, for: .normal)
    return btn
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    view.backgroundColor = UIColor.white
    view.addSubview(cancelButton)
    view.addSubview(imgView)
    view.addSubview(stackView)
    stackView.addArrangedSubview(idTextField)
    stackView.addArrangedSubview(passWordTextField)
    stackView.addArrangedSubview(authButton)
    stackView.addArrangedSubview(forgotPasswordButton)
    
    cancelButton.snp.makeConstraints { (make) in
      cancelButton.sizeToFit()
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(20)
    }
    
    imgView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-UIScreen.main.bounds.height / 8)
      make.width.height.equalTo(UIScreen.main.bounds.height / 4)
      make.bottom.equalTo(stackView.snp.top).offset(-20)
    }
    
    stackView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(30)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-30)
      make.height.equalTo(UIScreen.main.bounds.height / 4)
    }
  }
  
  func bindViewModel() {
    
    Observable.combineLatest(idTextField.rx.text.orEmpty, passWordTextField.rx.text.orEmpty)
      .map { (tuple) -> Bool in
        if tuple.0.isEmpty || tuple.1.isEmpty {
          return false
        } else { return true }
      }.bind(to: authButton.rx.isEnabled)
      .disposed(by: bag)
    
    Observable.combineLatest(viewModel.checkReachability().asObservable(),
                             viewModel.loggedIn.asObservable())
      .map { (tuple) -> String in
        if !tuple.0 { return "no internet connection" }
        else if tuple.1 { return "Logout" }
        else { return "Login" }
      }.asDriver(onErrorJustReturn: "failed")
      .drive(authButton.rx.title())
      .disposed(by: bag)
    
    authButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String) in
        let id = self.idTextField.text ?? ""
        let password = self.passWordTextField.text ?? ""
        return (id, password)
      })
      .bind(to: viewModel.onAuth.inputs)
      .disposed(by: bag)
    
    viewModel.onAuth.elements
      .asDriver(onErrorJustReturn: .unavailable("request failed"))
      .drive(onNext: { [unowned self] status in
        switch status {
        case .authorized: self.viewModel.goToSidebarScene()
        case .unavailable(let value): self.alertErrorMsg(message: value)
        }
      })
      .disposed(by: bag)
    
    
    forgotPasswordButton.rx.action = viewModel.onForgotPassword()
    cancelButton.rx.action = viewModel.onCancel
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
  }
  
  private func alertErrorMsg(message: String) {
    let alert = UIAlertController(title: "Login Failed",
                                  message: message,
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK",
                                  style: .default,
                                  handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
}
