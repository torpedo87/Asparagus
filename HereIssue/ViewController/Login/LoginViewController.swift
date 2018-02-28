//
//  LoginViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginViewController: UIViewController, BindableType {
  var viewModel: LoginViewModel!
  private let bag = DisposeBag()
  private let imgView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage(named: "issue")
    view.contentMode = .scaleAspectFill
    return view
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
  private var loginButton: UIButton = {
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
    title = "Login"
    view.backgroundColor = UIColor.white
    view.addSubview(imgView)
    view.addSubview(idTextField)
    view.addSubview(passWordTextField)
    view.addSubview(loginButton)
    view.addSubview(forgotPasswordButton)
    
    imgView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.width.height.equalTo(UIScreen.main.bounds.height / 4)
      make.bottom.equalTo(idTextField.snp.top).offset(-10)
    }
    
    idTextField.snp.makeConstraints({ (make) in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-100)
      make.width.equalTo(UIScreen.main.bounds.width * 2 / 3)
      make.height.equalTo(UIScreen.main.bounds.height / 15)
    })
    
    passWordTextField.snp.makeConstraints({ (make) in
      make.centerX.equalToSuperview()
      make.top.equalTo(idTextField.snp.bottom).offset(10)
      make.width.height.equalTo(idTextField)
    })
    
    loginButton.snp.makeConstraints({ (make) in
      loginButton.sizeToFit()
      make.centerX.equalToSuperview()
      make.top.equalTo(passWordTextField.snp.bottom).offset(10)
    })
    
    forgotPasswordButton.snp.makeConstraints { (make) in
      forgotPasswordButton.sizeToFit()
      make.centerX.equalToSuperview()
      make.top.equalTo(loginButton.snp.bottom).offset(10)
    }
  }
  
  func bindViewModel() {
    
    idTextField.rx.text.orEmpty
      .bind(to: viewModel.idTextInput)
      .disposed(by: bag)
    passWordTextField.rx.text.orEmpty
      .bind(to: viewModel.pwdTextInput)
      .disposed(by: bag)
    
    viewModel.checkReachability()
      .debug("----wifi------")
      .asDriver(onErrorJustReturn: false)
      .map { $0 ? "login" : "no internet connection." }
      .drive(loginButton.rx.title())
      .disposed(by: bag)
    
    viewModel.validate
      .drive(loginButton.rx.isEnabled)
      .disposed(by: bag)
    
    loginButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map { [unowned self] _ -> (String, String) in
        if let id = self.idTextField.text,
          let pwd = self.passWordTextField.text {
          return (id, pwd)
        }
        return ("", "")
    }
    .subscribe(viewModel.loginAction.inputs)
    .disposed(by: bag)
    
    viewModel.loginAction.elements
      .asDriver(onErrorJustReturn: .unavailable("login failed"))
      .drive(onNext: { [unowned self] status in
        switch status {
        case .authorized(let token): self.viewModel.goToTaskScene()
        case .unavailable(let value): self.alertErrorMsg(message: value)
        }
      })
      .disposed(by: bag)
    
    
    forgotPasswordButton.rx.action = viewModel.onForgotPassword()
  }
  
  func alertErrorMsg(message: String) {
    let alert = UIAlertController(title: "Login Failed",
                                  message: message,
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK",
                                  style: .default,
                                  handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
}
