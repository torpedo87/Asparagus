//
//  SidebarViewController.swift
//  Asparagus
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
  private var leftViewController: LeftViewController!
  private var mainNav: UINavigationController!
  private var overlap: CGFloat = 70
  private lazy var scrollView: UIScrollView = {
    let view = UIScrollView()
    view.backgroundColor = UIColor.white
    view.isPagingEnabled = true
    view.bounces = false
    view.showsVerticalScrollIndicator = false
    view.showsHorizontalScrollIndicator = false
    return view
  }()
  
  private lazy var contentView: UIView = {
    let view = UIView()
    return view
  }()
  
  convenience init(leftVC: LeftViewController, mainNav: UINavigationController){
    self.init()
    self.leftViewController = leftVC
    self.mainNav = mainNav
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupViewControllers()
    closeLeftMenuAnimated(false)
  }
  
  func bindViewModel() {
    viewModel.menuTap
      .subscribe(onNext: { [unowned self] in
        self.toggleLeftMenuAnimated(true)
      })
      .disposed(by: bag)
    
    viewModel.repoTap
      .subscribe(onNext: { [unowned self] in
        self.toggleLeftMenuAnimated(true)
      })
      .disposed(by: bag)
    
    viewModel.isScroll
      .bind(to: scrollView.rx.isScrollEnabled)
      .disposed(by: bag)
  }
  
  func setupView() {
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    scrollView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      } else {
        make.edges.equalTo(view)
      }
    }
    contentView.snp.makeConstraints { (make) in
      make.centerX.equalTo(view.frame.width - overlap / 2)
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.top.bottom.equalTo(view)
      }
    }
  }
  
  func setupViewControllers() {
    addViewController(leftViewController)
    addViewController(mainNav)
    
    leftViewController.view.snp.makeConstraints { (make) in
      make.left.top.equalTo(contentView)
      make.width.equalTo(view.frame.width - overlap)
      make.height.equalTo(view.frame.height)
      make.right.equalTo(mainNav.view.snp.left)
    }
    
    mainNav.view.snp.makeConstraints { (make) in
      make.right.top.equalTo(contentView)
      make.width.equalTo(view.frame.width)
      make.height.equalTo(contentView)
    }
    if #available(iOS 11.0, *) {
      let w = 2 * (UIScreen.main.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right) - overlap
      let h = UIScreen.main.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
      scrollView.contentSize = CGSize(width: w, height: h)
    } else {
      let w = 2 * (UIScreen.main.bounds.width) - overlap
      let h = UIScreen.main.bounds.height
      scrollView.contentSize = CGSize(width: w, height: h)
    }
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
    scrollView.setContentOffset(CGPoint(x: leftViewController.view.frame.width, y: 0),
                                animated: animated)
  }
  
  func toggleLeftMenuAnimated(_ animated: Bool) {
    if leftMenuIsOpened() {
      closeLeftMenuAnimated(animated)
    } else {
      openLeftMenuAnimated(animated)
    }
  }
}
