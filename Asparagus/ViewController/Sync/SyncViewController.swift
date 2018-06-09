//
//  SyncViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 1..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxKeyboard

class SyncViewController: UIViewController, BindableType {
  var viewModel: SyncViewModel!
  private let bag = DisposeBag()
  
  private lazy var doneBarButtonItem: UIBarButtonItem = {
    let item = UIBarButtonItem(barButtonSystemItem: .done,
                               target: self,
                               action: nil)
    return item
  }()
  private lazy var imgView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFill
    return view
  }()
  private lazy var toggleSwitch: UISwitch = {
    let item = UISwitch()
    return item
  }()
  private lazy var descriptionLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 3
    label.textAlignment = .center
    return label
  }()
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.isLoggedIn().asDriver(onErrorJustReturn: false)
      .drive(toggleSwitch.rx.value)
      .disposed(by: bag)
  }
  
  func setupView() {
    title = "Sync"
    navigationItem.rightBarButtonItem = doneBarButtonItem
    view.backgroundColor = UIColor.white
    
    view.addSubview(imgView)
    view.addSubview(toggleSwitch)
    view.addSubview(descriptionLabel)
    
    imgView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
      } else {
        make.top.equalTo(view).offset(50)
      }
      make.centerX.equalToSuperview()
      make.width.height.equalTo(UIScreen.main.bounds.width / 3)
    }
    
    toggleSwitch.snp.makeConstraints { (make) in
      toggleSwitch.transform = CGAffineTransform(scaleX: 2.0, y: 1.7)
      make.top.equalTo(imgView.snp.bottom).offset(10)
      make.centerX.equalToSuperview()
    }
    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(toggleSwitch.snp.bottom).offset(30)
      make.centerX.equalToSuperview()
      make.width.equalTo(200)
      descriptionLabel.sizeToFit()
    }
  }
  
  func bindViewModel() {
    viewModel.isLoggedIn()
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: { [unowned self] bool in
        self.imgView.image = bool ? UIImage(named: "synced") : UIImage(named: "unsynced")
      })
      .disposed(by: bag)
    
    viewModel.isLoggedIn().asDriver(onErrorJustReturn: false)
      .map { bool -> String in
        if bool {
          if let me = UserDefaults.loadUser() {
            return "@\(me.name) is Active"
          }
          return "Your Account is Active"
        }
        else { return "Tap the switch to sync with Github account"}
      }
      .drive(descriptionLabel.rx.text)
      .disposed(by: bag)
    
    doneBarButtonItem.rx.action = viewModel.dismissView()
    
    toggleSwitch.rx.isOn
      .skip(1)
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: { [unowned self] bool in
        self.navigationController?.pushViewController(self.viewModel.authVC(), animated: true)
      })
      .disposed(by: bag)
  }
  
}

extension SyncViewController: UIPopoverPresentationControllerDelegate {
  func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
  }
  
  func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
    return false
  }
}
