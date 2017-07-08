//
//  PanInteractionManager.swift
//  PingTransitionDemo
//
//  Created by Hisen on 2017/7/7.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import UIKit

class PanInteractionManager: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    
    fileprivate var shouldCompleteTransition = false
    fileprivate weak var viewController: UIViewController!
    
    func wireToViewController(_ viewController: UIViewController!) {
        self.viewController = viewController
        prepareGestureRecognizerInView(viewController.view)
    }
    
    fileprivate func prepareGestureRecognizerInView(_ view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (translation.y / 200)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        switch gestureRecognizer.state {
            
            case .began:
                interactionInProgress = true
                viewController.dismiss(animated: true, completion: nil)
            case .changed:
                shouldCompleteTransition = progress > 0.5
                update(progress)
            case .cancelled:
                interactionInProgress = false
                cancel()
            case .ended:
                interactionInProgress = false
                if !shouldCompleteTransition {
                    cancel()
                } else {
                    finish()
                }
            
            default:
                print("Unsupported")
        }
    }
}
