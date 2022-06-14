//
//  NullAnimator.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

class BottomSheetControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let bottomSheet: BottomSheetController

    init(isPresenting: Bool, bottomSheet: BottomSheetController) {
        self.isPresenting = isPresenting
        self.bottomSheet = bottomSheet
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? 0 : BottomSheetController.dismissalSpeed
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            transitionContext.viewController(forKey: .from)?.view.tintAdjustmentMode = .dimmed
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        } else {
            bottomSheet.animateDismiss {
                transitionContext.viewController(forKey: .to)?.view.tintAdjustmentMode = .automatic
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
