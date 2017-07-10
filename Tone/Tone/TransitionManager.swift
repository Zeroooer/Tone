//
//  TransitionManager.swift
//  PingTransitionDemo
//
//  Created by Hisen on 2017/7/6.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import UIKit

enum TransitionType {
    case present
    case dismiss
}

class TransitionManager: NSObject {
    
    var transitonType: TransitionType = .present
    
    var transitionContext: UIViewControllerContextTransitioning?
    
    var panInteractionManager: PanInteractionManager?
    
    var baseFrame: CGRect?

}

// MARK: UIViewControllerAnimatedTransitioning
extension TransitionManager: UIViewControllerAnimatedTransitioning {

    // custom transiton animation
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        self.transitionContext = transitionContext
        
        let container = transitionContext.containerView
        container.backgroundColor = UIColor.white
        
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!

        switch transitonType {
            case .present:
                container.addSubview(fromView)
                container.addSubview(toView)

            case .dismiss:
                container.addSubview(toView)
                container.addSubview(fromView)

        }
        
        let maskStartBP = UIBezierPath(ovalIn: baseFrame!)
        let center = CGPoint(x: (baseFrame?.origin.x)! + (baseFrame?.size.width)! / 2, y: (baseFrame?.origin.y)! + (baseFrame?.size.height)! / 2)
        let radius = sqrt(center.x * center.x + center.y * center.y) - 50
        let maskFinalBP = UIBezierPath(ovalIn: (baseFrame!.insetBy(dx: -radius, dy: -radius)))
        
        // get the duration of the animation
        // DON'T just type '0.5s' -- the reason why won't make sense until the next post
        // but for now it's important to just follow this approach
        let duration = self.transitionDuration(using: transitionContext)
        
        //创建一个CAShapeLayer 来负责展示圆形遮盖
        let maskLayer = CAShapeLayer()
        
        let maskLayerAnimation = CAKeyframeAnimation(keyPath: "path")
        switch transitonType {
            case .present:
                maskLayer.path = maskFinalBP.cgPath
                toView.layer.mask = maskLayer
                maskLayerAnimation.values = [maskStartBP.cgPath, maskFinalBP.cgPath]
            case .dismiss:
                maskLayer.path = maskStartBP.cgPath
                fromView.layer.mask = maskLayer
                maskLayerAnimation.values = [maskFinalBP.cgPath, maskStartBP.cgPath]
        }
        maskLayerAnimation.duration = duration
        maskLayerAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)]
        maskLayerAnimation.delegate = self
        
        maskLayer.add(maskLayerAnimation, forKey: "ping")
    }
    
    // return how many seconds the transiton animation will take
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
}

// MARK: UIViewControllerTransitioningDelegate
extension TransitionManager: UIViewControllerTransitioningDelegate {
    // return the animataor when presenting a viewcontroller
    // remmeber that an animator (or animation controller) is any object that aheres to the UIViewControllerAnimatedTransitioning protocol
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitonType = .present
        return self
    }
    
    // return the animator used when dismissing from a viewcontroller
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitonType = .dismiss
        return self
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return (panInteractionManager?.interactionInProgress)! ? panInteractionManager : nil
    }
}

extension TransitionManager: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.transitionContext?.completeTransition(flag)
        self.transitionContext?.viewController(forKey: UITransitionContextViewControllerKey.from)?.view.layer.mask = nil
        self.transitionContext?.viewController(forKey: UITransitionContextViewControllerKey.to)?.view.layer.mask = nil
    }
}
