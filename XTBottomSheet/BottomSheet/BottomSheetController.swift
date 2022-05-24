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

        dimmView.backgroundColor = .black.withAlphaComponent(dimmMaxAlpha)
        view.addSubview(dimmView)
        dimmView.frame = view.bounds
        dimmView.autoresizingMask = [.flexibleWidth, .flexibleHeight]


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

        dimmView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
        bottomSheet.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:))))

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
            super.dismiss(animated: flag, completion: completion)
        }
    }

    func animatedDismiss(fast: Bool = false, completion: (() -> Void)? = nil) {
        animating = true
        if fast {
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: [.beginFromCurrentState]) { [self] in
                moveContainerBottom()
            } completion: { [self] _ in
                dismiss(animated: false, completion: completion)
            }
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState]) { [self] in
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

    var startConst: CGFloat = 0
}

// MARK: - Private
private extension BottomSheetController {
    func moveContainerTop() {
        guard !dragging else { return }

        dimmView.alpha = 1
        heightConstraint.isActive = false
        heightConstraint.constant = min(getContentHeight(), heightLimit)
//        heightConstraint.constant = getContentHeight()
        heightConstraint.isActive = true
        view.layoutIfNeeded()
    }

    func moveContainerBottom() {
        guard !dragging else { return }

        dimmView.alpha = 0
        heightConstraint.constant = 0
        view.layoutIfNeeded()
    }

    func getContentHeight() -> CGFloat {
        bottomSheet.view.layoutIfNeeded()
        return bottomSheet.containerView.frame.height
    }

    @objc func dismissSelf() {
        dismiss(animated: true)
    }

    @objc func panGesture(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: view)

        switch pan.state {
        case .began:
            startConst = heightConstraint.constant
            fallthrough
        case .changed:
            dragging = true
            if translation.y > 0 {
                heightConstraint.constant = max(startConst - translation.y, 0)
            } else {
                let l = logC(-translation.y / 30 + 1, base: 2) * 4
                heightConstraint.constant = max(startConst + l, 0)
            }

            let percent = min(heightConstraint.constant / getContentHeight(), 1)
            dimmView.alpha = percent
        case .ended, .failed:
            let velocity = pan.velocity(in: view)
            let projection = startConst - translation.y - project(initialVelocity: velocity.y, decelerationRate: UIScrollView.DecelerationRate.fast.rawValue)

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

extension BottomSheetController: BottomSheetContainerDelegate {
    var heightLimit: CGFloat {
        view.frame.height - view.safeAreaInsets.top - 44
    }

    func scrollViewContentSizeChanged() {
        guard !dragging else { return }
        baseAnimation(moveContainerTop)
    }
}

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

class PresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = containerView!.bounds
        return CGRect(x: 0,
                      y: 0,
                      width: bounds.width,
                      height: bounds.height)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.addSubview(presentedView!)
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
