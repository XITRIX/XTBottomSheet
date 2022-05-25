//
//  BottomSheetController.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

class BottomSheetController: UIViewController {
    let dimmView: UIView!
    let rootViewController: UIViewController
    let bottomSheet: BottomSheetContainer
    let dimmMaxAlpha: CGFloat = 0.3
    var heightConstraint: NSLayoutConstraint!
    var dragging: Bool = false
    var animating: Bool = false
    var heightObserver: NSKeyValueObservation?
    var enableMagnification = false

    // MARK: - Init
    public init(rootViewController: UIViewController) {
        self.dimmView = UIView()
        self.rootViewController = rootViewController
        self.bottomSheet = BottomSheetContainer(rootViewController: rootViewController)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup DimmView
        dimmView.backgroundColor = UIColor(named: "DimmColor")
        view.addSubview(dimmView)
        dimmView.frame = view.bounds
        dimmView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmView.layer.cornerCurve = .continuous

        // Setup BottomSheetContainer
        addChild(bottomSheet)
        view.addSubview(bottomSheet.view)
        bottomSheet.didMove(toParent: self)

        bottomSheet.delegate = self

        bottomSheet.view.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = bottomSheet.view.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            heightConstraint,
            bottomSheet.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheet.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Setup Gesture recognizers
        dimmView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        pan.allowedScrollTypesMask = .continuous
        pan.delegate = self
        bottomSheet.view.addGestureRecognizer(pan)

        // Setup content size observer
        heightObserver = bottomSheet.containerView.observe(\.bounds, options: [.old, .new], changeHandler: { [unowned self] _, _ in
            guard !animating, !dragging else { return }
            baseAnimation(moveContainerTop)
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        moveContainerBottom()
        baseAnimation(moveContainerTop)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            animatedDismiss(completion: completion)
        } else {
            removeMagnification()
            super.dismiss(animated: flag, completion: completion)
        }
    }

    func animatedDismiss(fast: Bool = false, completion: (() -> Void)? = nil) {
        animating = true

        let dismissalSpeed = 0.2
        if fast {
            UIView.animate(withDuration: dismissalSpeed, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: [.beginFromCurrentState]) { [self] in
                moveContainerBottom()
            } completion: { [self] _ in
                dismiss(animated: false, completion: completion)
            }
        } else {
            UIView.animate(withDuration: dismissalSpeed, delay: 0, options: [.beginFromCurrentState]) { [self] in
                moveContainerBottom()
            } completion: { [self] _ in
                dismiss(animated: false, completion: completion)
            }
        }
    }

    // MARK: - Overrides
    override public var modalPresentationStyle: UIModalPresentationStyle {
        get { .custom }
        set {}
    }

    override public var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { self }
        set {}
    }

    override public var modalTransitionStyle: UIModalTransitionStyle {
        get { .crossDissolve }
        set {}
    }
}

// MARK: - Private
private extension BottomSheetController {
    func moveContainerTop() {
        guard !dragging else { return }

        dimmView.alpha = 1
        heightConstraint.isActive = false
        heightConstraint.constant = min(getContentHeight(), heightLimit)
        heightConstraint.isActive = true
        view.layoutIfNeeded()
        magnifyParent(progress: 1)
    }

    func moveContainerBottom() {
        guard !dragging else { return }

        dimmView.alpha = 0
        heightConstraint.constant = 0
        view.layoutIfNeeded()
        magnifyParent(progress: 0)
    }

    func getContentHeight() -> CGFloat {
        bottomSheet.containerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }

    @objc func dismissSelf() {
        dismiss(animated: true)
    }

    @objc func panGesture(_ pan: UIPanGestureRecognizer) {
        guard !shouldPanFail(pan) else {
            pan.setTranslation(.zero, in: view)
            return
        }

        let translation = pan.translation(in: view)

        switch pan.state {
        case .began, .changed:
            dragging = true
            if translation.y > 0 {
                heightConstraint.constant = max(getContentHeight() - translation.y, 0)
            } else {
                // Calculating spring effect
                let spring = log2(-translation.y / 30 + 1) * 3
                heightConstraint.constant = max(getContentHeight() + spring, 0)
            }

            let progress = min(heightConstraint.constant / getContentHeight(), 1)
            dimmView.alpha = progress
            magnifyParent(progress: progress)
        case .ended:
            let velocity = pan.velocity(in: view)
            let projection = getContentHeight() - translation.y - project(initialVelocity: velocity.y, decelerationRate: UIScrollView.DecelerationRate.fast.rawValue)

            if projection < getContentHeight() / 2 {
                dragging = false
                animatedDismiss(fast: true)
                break
            }
            fallthrough
        default:
            dragging = false
            baseAnimation(moveContainerTop)
        }
    }

    func shouldPanFail(_ pan: UIPanGestureRecognizer) -> Bool {
        if let scrollView = bottomSheet.scrollView {
            guard scrollView.panGestureRecognizer.state != .possible else { return false }

            let scrollToTop = {
                // Use main.async to reduce visual lag due to the offset changed by scrollView.panGestureRecognizer action
                DispatchQueue.main.async {
                    scrollView.setContentOffset(.init(x: 0, y: -scrollView.safeAreaInsets.top), animated: false)
                }
            }

            if pan.velocity(in: view).y > 0 {
                let offset = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
                if offset > 0 {
                    return true
                } else {
                    if offset < -10 {
                        pan.setTranslation(.init(x: 0, y: -offset), in: view)
                    }
                    scrollToTop()
                    return false
                }
            } else {
                if heightConstraint.constant < heightLimit {
                    scrollToTop()
                    return false
                } else {
                    return true
                }
            }
        }

        return false
    }

    func baseAnimation(_ animation: @escaping () -> Void) {
        animating = true
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
            animation()
        } completion: { [self] _ in
            animating = false
        }
    }
}

// MARK: - Parent magnification
private extension BottomSheetController {
    func magnifyParent(progress: CGFloat) {
        guard enableMagnification else { return }
        guard getContentHeight() >= heightLimit
        else {
            dimmView.transform = CGAffineTransform.identity
            dimmView.layer.cornerRadius = UIScreen.main.displayCornerRadius
            presentingViewController?.view.transform = CGAffineTransform.identity
            presentingViewController?.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
            return
        }

        let magnificationRate = 0.9
        let minimunCornerRadius = 10.0

        let size = (1 - progress) * (1 - magnificationRate) + magnificationRate
        let radius = (UIScreen.main.displayCornerRadius - minimunCornerRadius) * (1 - progress) + minimunCornerRadius
        let transform = CGAffineTransform(scaleX: size, y: size)

        dimmView.transform = transform
        dimmView.layer.cornerRadius = radius
        presentingViewController?.view.transform = transform
        presentingViewController?.view.layer.cornerRadius = radius
    }

    func removeMagnification() {
        dimmView.layer.cornerRadius = 0
        dimmView.transform = CGAffineTransform.identity
        presentingViewController?.view.layer.cornerRadius = 0
        presentingViewController?.view.transform = CGAffineTransform.identity
    }
}

// MARK: - Parent BottomSheetContainerDelegate
extension BottomSheetController: BottomSheetContainerDelegate {
    var heightLimit: CGFloat {
        let extraTopOffset = 10.0
        return view.frame.height - view.safeAreaInsets.top - extraTopOffset
    }

    func scrollViewContentSizeChanged() {
        guard !dragging else { return }
        baseAnimation(moveContainerTop)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BottomSheetController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer == bottomSheet.scrollView?.panGestureRecognizer
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension BottomSheetController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        NullAnimator()
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        NullAnimator()
    }
}
