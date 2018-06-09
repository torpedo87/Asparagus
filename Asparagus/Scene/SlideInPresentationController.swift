//
//  SlideInPresentationController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 6. 8..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxKeyboard

class SlideInPresentationController: UIPresentationController {
  fileprivate var dimmingView: UIView!
  private var direction: PresentationDirection
  private let bag = DisposeBag()
  
  init(presentedViewController: UIViewController,
       presenting presentingViewController: UIViewController?,
       direction: PresentationDirection) {
    self.direction = direction
    super.init(presentedViewController: presentedViewController,
               presenting: presentingViewController)
    setupDimmingView()
    bindKeyboard()
  }
  
  override func presentationTransitionWillBegin() {
    containerView?.insertSubview(dimmingView, at: 0)
    containerView?.isUserInteractionEnabled = true
    dimmingView.snp.makeConstraints { (make) in
      make.edges.equalTo(containerView!)
    }
    
    guard let coordinator = presentedViewController.transitionCoordinator else {
      dimmingView.alpha = 1.0
      return
    }
    
    coordinator.animate(alongsideTransition: { _ in
      self.dimmingView.alpha = 1.0
    }, completion: nil)
  }
  
  override func dismissalTransitionWillBegin() {
    guard let coordinator = presentedViewController.transitionCoordinator else {
      dimmingView.alpha = 1.0
      return
    }
    coordinator.animate(alongsideTransition: { _ in
      self.dimmingView.alpha = 0
    }, completion: nil)
  }
  
  override func containerViewWillLayoutSubviews() {
    presentedView?.frame = frameOfPresentedViewInContainerView
  }
  
  override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
    switch direction {
    case .left, .right:
      return CGSize(width: parentSize.width * 2 / 3, height: parentSize.height)
    case .bottom, .top:
      return CGSize(width: parentSize.width, height: parentSize.height / 3)
    }
  }
  
  override var frameOfPresentedViewInContainerView: CGRect {
    var frame = CGRect.zero
    frame.size = size(forChildContentContainer: presentedViewController,
                      withParentContainerSize: containerView!.bounds.size)
    
    switch direction {
    case .right:
      frame.origin.x = containerView!.frame.width / 3
    case .bottom:
      frame.origin.y = containerView!.frame.height * 2 / 3
    default:
      frame.origin = .zero
    }
    return frame
  }
}

extension SlideInPresentationController {
  func setupDimmingView() {
    dimmingView = UIView()
    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
    dimmingView.alpha = 0.0
    
    dimmingView.rx.tapGesture()
      .asDriver()
      .drive(onNext: { [unowned self] _ in
        self.presentedView?.endEditing(true)
      })
      .disposed(by: bag)
  }
  
  func bindKeyboard() {
    RxKeyboard.instance.visibleHeight
      .drive(onNext: { [unowned self] keyboardVisibleHeight in
        var actualHeight: CGFloat = 0
        if keyboardVisibleHeight >= 0 {
          actualHeight = keyboardVisibleHeight + 10
        } else {
          actualHeight = keyboardVisibleHeight - 10
        }
        if let vc = self.presentedViewController as? PopupViewController {
          UIView.animate(withDuration: 0.5, animations: {
            vc.containerView.snp.updateConstraints({ (make) in
              if #available(iOS 11.0, *) {
                make.bottom.equalTo(vc.view.safeAreaLayoutGuide.snp.bottom).offset(-actualHeight)
              } else {
                make.bottom.equalTo(vc.view).offset(-actualHeight)
              }
            })
            vc.view.layoutIfNeeded()
          })
        }
      })
      .disposed(by: bag)
  }
  
  func popView() {
    presentingViewController.dismiss(animated: true)
  }

}
