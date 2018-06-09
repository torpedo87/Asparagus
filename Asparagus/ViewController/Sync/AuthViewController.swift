//
//  AuthViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AuthViewController: UIViewController, BindableType {
  var viewModel: SyncViewModel!
  private let bag = DisposeBag()
  
  private lazy var stackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
  }()
  private lazy var idView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hex: "DBD9DB")
    view.layer.cornerRadius = 10
    return view
  }()
  private lazy var passwordView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hex: "DBD9DB")
    view.layer.cornerRadius = 10
    return view
  }()
  private lazy var idLabel: UILabel = {
    let label = UILabel()
    label.backgroundColor = UIColor.clear
    label.text = "ID"
    return label
  }()
  private lazy var passwordLabel: UILabel = {
    let label = UILabel()
    label.backgroundColor = UIColor.clear
    label.text = "Password"
    return label
  }()
  private lazy var idTextField: UITextField = {
    let txtField = UITextField()
    txtField.placeholder = "GitHub ID"
    txtField.backgroundColor = UIColor.clear
    txtField.autocapitalizationType = .none
    return txtField
  }()
  private lazy var passWordTextField: UITextField = {
    let txtField = UITextField()
    txtField.placeholder = "Required"
    txtField.backgroundColor = UIColor.clear
    txtField.autocapitalizationType = .none
    txtField.isSecureTextEntry = true
    return txtField
  }()
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.isEnabled = false
    btn.setTitleColor(.white, for: .normal)
    btn.backgroundColor = .blue
    btn.layer.cornerRadius = 10
    return btn
  }()
  private lazy var forgotPasswordButton: UIButton = {
    let btn = UIButton()
    btn.setTitle(" Forget your password?", for: .normal)
    btn.setTitleColor(UIColor.blue, for: .normal)
    return btn
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    title = "Github account"
    view.backgroundColor = UIColor.white
    view.addSubview(stackView)
    stackView.addArrangedSubview(idView)
    stackView.addArrangedSubview(passwordView)
    stackView.addArrangedSubview(forgotPasswordButton)
    stackView.addArrangedSubview(authButton)
    idView.addSubview(idLabel)
    idView.addSubview(idTextField)
    passwordView.addSubview(passwordLabel)
    passwordView.addSubview(passWordTextField)
    idLabel.snp.makeConstraints { (make) in
      make.left.equalTo(idView).offset(5)
      make.top.bottom.equalTo(idView)
      make.width.equalTo(80)
    }
    idTextField.snp.makeConstraints { (make) in
      make.right.top.bottom.equalTo(idView)
      make.left.equalTo(idLabel.snp.right)
    }
    passwordLabel.snp.makeConstraints { (make) in
      make.left.equalTo(passwordView).offset(5)
      make.top.bottom.equalTo(passwordView)
      make.width.equalTo(80)
    }
    passWordTextField.snp.makeConstraints { (make) in
      make.right.top.bottom.equalTo(passwordView)
      make.left.equalTo(passwordLabel.snp.right)
    }
    
    stackView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.height.equalTo(UIScreen.main.bounds.height / 4)
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(20)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-20)
      } else {
        make.top.equalTo(view).offset(50)
        make.left.equalTo(view).offset(20)
        make.right.equalTo(view).offset(-20)
      }
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
    
    Observable.combineLatest(Reachability.rx.isOnline,
                             viewModel.isLoggedIn())
      .map { (tuple) -> String in
        if !tuple.0 { return "no internet connection" }
        else if tuple.1 { return "Disconnect" }
        else { return "Connect" }
      }
      .asDriver(onErrorJustReturn: "failed")
      .drive(authButton.rx.title())
      .disposed(by: bag)
    
    let onAuth = viewModel.onAuthTask()
    
    authButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String) in
        let id = self.idTextField.text ?? ""
        let password = self.passWordTextField.text ?? ""
        return (id, password)
      })
      .bind(to: onAuth.inputs)
      .disposed(by: bag)
    
    onAuth.elements
      .asDriver(onErrorJustReturn: .unavailable("request failed"))
      .drive(onNext: { [unowned self] status in
        switch status {
        case .authorized: self.navigationController?.popViewController(animated: true)
        case .unavailable(let value): self.alertErrorMsg(message: value)
        }
      })
      .disposed(by: bag)
    
    
    forgotPasswordButton.rx.action = viewModel.onForgotPassword()
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
    
  }
  
  private func alertErrorMsg(message: String) {
    let alert = UIAlertController(title: "Connect Failed",
                                  message: message,
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK",
                                  style: .default,
                                  handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
}
