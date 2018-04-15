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
import RxGesture
import RxKeyboard

class AuthViewController: UIViewController, BindableType {
  var viewModel: AuthViewModel!
  private let bag = DisposeBag()
  private lazy var cancelButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("CANCEL", for: .normal)
    btn.setTitleColor(UIColor.blue, for: .normal)
    return btn
  }()
  private lazy var imgView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFill
    return view
  }()
  private lazy var stackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.alignment = .fill
    stack.distribution = .fillEqually
    return stack
  }()
  private lazy var idTextField: UITextField = {
    let txtField = UITextField()
    txtField.placeholder = "Please enter your GitHub ID"
    txtField.layer.borderColor = UIColor(hex: "2E3136").cgColor
    txtField.layer.borderWidth = 0.5
    return txtField
  }()
  private lazy var passWordTextField: UITextField = {
    let txtField = UITextField()
    txtField.placeholder = " Please enter your password"
    txtField.layer.borderColor = UIColor(hex: "2E3136").cgColor
    txtField.isSecureTextEntry = true
    txtField.layer.borderWidth = 0.5
    return txtField
  }()
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.isEnabled = false
    btn.setTitleColor(UIColor.blue, for: .normal)
    btn.setTitleColor(UIColor.gray, for: .disabled)
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
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(20)
      } else {
        make.top.left.equalTo(view).offset(20)
      }
    }
    
    imgView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-UIScreen.main.bounds.height / 8)
      make.width.height.equalTo(UIScreen.main.bounds.height / 4)
      make.bottom.equalTo(stackView.snp.top).offset(-20)
    }
    
    stackView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.height.equalTo(UIScreen.main.bounds.height / 4)
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(30)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-30)
      } else {
        make.left.equalTo(view).offset(30)
        make.right.equalTo(view).offset(-30)
      }
    }
  }
  
  func bindViewModel() {
    RxKeyboard.instance.visibleHeight
      .skip(1)
      .filter{ $0 == 0}
      .drive(onNext: { [unowned self] _ in
        UIView.animate(withDuration: 1.0) {
          self.imgView.snp.updateConstraints { make in
            make.centerY.equalToSuperview().offset(-UIScreen.main.bounds.height / 8)
          }
          self.view.layoutIfNeeded()
        }
      })
      .disposed(by: bag)
    
    RxKeyboard.instance.willShowVisibleHeight
      .drive(onNext: { [unowned self] _ in
        UIView.animate(withDuration: 1.0) {
          self.imgView.snp.updateConstraints { make in
            make.centerY.equalToSuperview().offset(-UIScreen.main.bounds.height / 5)
          }
          self.view.layoutIfNeeded()
        }
      })
      .disposed(by: bag)
    
    Observable.combineLatest(idTextField.rx.text.orEmpty, passWordTextField.rx.text.orEmpty)
      .map { (tuple) -> Bool in
        if tuple.0.isEmpty || tuple.1.isEmpty {
          return false
        } else { return true }
      }.bind(to: authButton.rx.isEnabled)
      .disposed(by: bag)
    
    Observable.combineLatest(Reachability.rx.isOnline,
                             viewModel.isLoggedIn.asObservable())
      .map { (tuple) -> String in
        if !tuple.0 { return "no internet connection" }
        else if tuple.1 { return "Disconnect" }
        else { return "Connect" }
      }
      .asDriver(onErrorJustReturn: "failed")
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
    cancelButton.rx.action = viewModel.dismissView()
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
    
    viewModel.isLoggedIn.asObservable()
      .subscribe(onNext: { [unowned self] bool in
        if bool {
          if let me = UserDefaults.loadUser(), let imgUrl = me.imgUrl {
            do {
              let imgData = try Data(contentsOf: imgUrl)
              self.imgView.image = UIImage(data: imgData)
            } catch {
              self.imgView.image = UIImage(named: "user")
            }
          }
        } else {
          self.imgView.image = UIImage(named: "user")
        }
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
