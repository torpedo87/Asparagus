//
//  RepositoryViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 25..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources

class RepositoryViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: DetailViewModel!
  private let container: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.yellow
    return view
  }()
  private let selectedRepositoryTextField: UITextField = {
    let view = UITextField()
    view.layer.borderWidth = 1.0
    view.isUserInteractionEnabled = false
    return view
  }()
  private let pickerView: UIPickerView = {
    let view = UIPickerView()
    view.backgroundColor = UIColor.green
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
  
  func bindViewModel() {
    viewModel.repoTitles
      .bind(to: pickerView.rx.itemTitles) { _, item in
        return "\(item)"
      }
      .disposed(by: bag)
    pickerView.rx.modelSelected(String.self)
      .map { models -> String in
        return models.first!
      }.bind(to: selectedRepositoryTextField.rx.text)
      .disposed(by: bag)
    
    selectedRepositoryTextField.rx.text.orEmpty
      .map { (title) -> Bool in
        if title.isEmpty { return false } else {
          return true
        }
      }.bind(to: saveButton.rx.isEnabled)
    
    cancelButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        self.viewModel.pop()
      })
      .disposed(by: bag)
    
    //repo 업데이트
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        
      })
      .disposed(by: bag)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    
  }
  
  func setupView() {
    title = "Repository"
    view.addSubview(container)
    container.addSubview(selectedRepositoryTextField)
    container.addSubview(pickerView)
    
    container.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 4 / 5)
      make.height.equalTo(UIScreen.main.bounds.height / 2)
    }
    
    selectedRepositoryTextField.snp.makeConstraints { (make) in
      make.left.equalTo(container.snp.left).offset(10)
      make.top.equalTo(container.snp.top).offset(10)
      make.right.equalTo(container.snp.right).offset(-10)
      make.height.equalTo(50)
    }
    pickerView.snp.makeConstraints { (make) in
      make.top.equalTo(selectedRepositoryTextField.snp.bottom).offset(10)
      make.left.right.equalTo(selectedRepositoryTextField)
      make.bottom.equalTo(container.snp.bottom).offset(-10)
    }
  }
}
