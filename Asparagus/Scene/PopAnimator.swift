//
//  PopAnimator.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 23..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit

class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  let duration = 0.5
  var presenting = true
  var originFrame = CGRect.zero
  
  var dismissCompletion: (()->Void)?
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return duration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    let containerView = transitionContext.containerView
    containerView.backgroundColor = UIColor.white
    guard let toView = transitionContext.view(forKey: .to) else { return }
    let presentedView = presenting ? toView : transitionContext.view(forKey: .from)!
    let presentedWidth = UIScreen.main.bounds.width * 3 / 4
    let presentedHeight = UIScreen.main.bounds.height / 3
    let presentedFrame =
      CGRect(origin: CGPoint(x: UIScreen.main.bounds.width / 2 - presentedWidth / 2,
                             y: UIScreen.main.bounds.height / 2 - presentedHeight / 2),
            size: CGSize(width: presentedWidth,
                         height: presentedHeight))
    let initialFrame = presenting ? originFrame : presentedFrame
    let finalFrame = presenting ? presentedFrame : originFrame
    
    let xScaleFactor = presenting ?
      initialFrame.width / finalFrame.width :
      finalFrame.width / initialFrame.width
    
    let yScaleFactor = presenting ?
      initialFrame.height / finalFrame.height :
      finalFrame.height / initialFrame.height
    
    let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
    
    if presenting {
      presentedView.transform = scaleTransform
      presentedView.center = CGPoint(
        x: initialFrame.midX,
        y: initialFrame.midY)
      presentedView.clipsToBounds = true
    }
    
    containerView.addSubview(toView)
    containerView.bringSubview(toFront: presentedView)
    
    
    UIView.animate(withDuration: duration, delay: 0.0,
                   usingSpringWithDamping: 1, initialSpringVelocity: 0.0,
                   animations: {
                    presentedView.transform = self.presenting ? CGAffineTransform.identity : scaleTransform
                    presentedView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
    }, completion: { _ in
      if !self.presenting {
        self.dismissCompletion?()
      }
      transitionContext.completeTransition(true)
    })
  }
}
