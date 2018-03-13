//
//  SidebarViewController.swift
//  HereIssue
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SidebarViewController: UIViewController, BindableType {
  
  var viewModel: SidebarViewModel!
  private let bag = DisposeBag()
  var leftViewController: LeftViewController!
  var mainViewController: UINavigationController!
  var overlap: CGFloat = 70
  var scrollView: UIScrollView = {
    let view = UIScrollView()
    view.backgroundColor = UIColor.white
    view.isPagingEnabled = true
    view.bounces = false
    return view
  }()
  
  var contentView: UIView = {
    let view = UIView()
    return view
  }()
  
  convenience init(leftVC: LeftViewController, mainVC: TaskViewController){
    self.init()
    self.leftViewController = leftVC
    self.mainViewController = UINavigationController(rootViewController: mainVC)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupViewControllers()
    closeLeftMenuAnimated(false)
  }
  
  func bindViewModel() {
    viewModel.menuTap.asDriver()
      .drive(onNext: { [unowned self] in
        self.toggleLeftMenuAnimated(true)
      })
      .disposed(by: bag)
    
    viewModel.repoTap.asDriver()
      .drive(onNext: { [unowned self] in
        self.toggleLeftMenuAnimated(true)
      })
      .disposed(by: bag)
  }
  
  func setupView() {
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    
    scrollView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
      make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
    }
    
    contentView.snp.makeConstraints { (make) in
      make.centerX.equalTo(view.frame.width - overlap / 2)
      make.top.bottom.equalTo(view)
    }
  }
  
  func setupViewControllers() {
    addViewController(leftViewController)
    addViewController(mainViewController)
    
    leftViewController.view.snp.makeConstraints { (make) in
      make.left.top.equalTo(contentView)
      make.width.equalTo(view.frame.width - overlap)
      make.height.equalTo(view)
      make.right.equalTo(mainViewController.view.snp.left)
    }
    
    mainViewController.view.snp.makeConstraints { (make) in
      make.right.top.equalTo(contentView)
      make.width.equalTo(view.frame.width)
      make.height.equalTo(view)
    }
    let w = 2 * UIScreen.main.bounds.width - overlap
    let h = UIScreen.main.bounds.height
    
    scrollView.contentSize = CGSize(width: w, height: h)
  }
  
  private func addViewController(_ viewController: UIViewController) {
    contentView.addSubview(viewController.view)
    addChildViewController(viewController)
    viewController.didMove(toParentViewController: self)
  }
  
  func leftMenuIsOpened() -> Bool {
    return scrollView.contentOffset.x == 0
  }
  
  func openLeftMenuAnimated(_ animated: Bool) {
    scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: animated)
  }
  
  func closeLeftMenuAnimated(_ animated: Bool) {
    scrollView.setContentOffset(CGPoint(x: leftViewController.view.frame.width, y: 0), animated: animated)
  }
  
  func toggleLeftMenuAnimated(_ animated: Bool) {
    if leftMenuIsOpened() {
      closeLeftMenuAnimated(animated)
    } else {
      openLeftMenuAnimated(animated)
    }
  }
}
