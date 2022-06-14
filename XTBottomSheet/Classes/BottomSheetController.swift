//
//  BottomSheetController.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

public protocol BottomSheetControllerDelegate: AnyObject {
    var scrollMode: BottomSheetController.ScrollMode { get }
}

public class BottomSheetController: UIViewController {
    // MARK: - Init
    public init(rootViewController: UIViewController, with config: Config = .init()) {
        self.dimmView = UIView()
        self.rootViewController = rootViewController
        self.isMagnificationEnabled = config.withParentMagnification
        self.bottomSheet = BottomSheetContainer(rootViewController: rootViewController, with: config)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle
    override public func viewDidLoad() {
        super.viewDidLoad()

        setupDimm()
        setupBottomSheetContainer()
        setupGestures()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        moveContainerBottom()
        baseAnimation(moveContainerTop)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [self] _ in
            updateLayout()
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            animateDismiss { [self] in
                dismiss(animated: false, completion: completion)
            }
        } else {
            removeMagnification()
            presentingViewController?.view.tintAdjustmentMode = .automatic
            super.dismiss(animated: flag, completion: completion)
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

    // MARK: - Private
    private var heightConstraint: NSLayoutConstraint!
    private var dragging: Bool = false
    private var animating: Bool = false
    private var heightObserver: NSKeyValueObservation?
    private var layouting = false
    private var lastContentHeight: CGFloat = 0

    // MARK: - Private constants
    private let dimmView: UIView!
    private let rootViewController: UIViewController
    private let bottomSheet: BottomSheetContainer
    private let maximumWidth: CGFloat = 500
    private let dimmColor = "DimmColor"
    private var isMagnificationEnabled = false

    // MARK: - Internal constants
    static let dismissalSpeed = 0.2
}

// MARK: - Private setup
private extension BottomSheetController {
    func setupDimm() {
        dimmView.backgroundColor = UIColor(named: dimmColor, in: Bundle(for: Self.self), compatibleWith: traitCollection)
        view.addSubview(dimmView)
        dimmView.frame = view.bounds
        dimmView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 13.0, *) {
            dimmView.layer.cornerCurve = .continuous
        }
    }

    func setupBottomSheetContainer() {
        addChild(bottomSheet)
        view.addSubview(bottomSheet.view)
        bottomSheet.didMove(toParent: self)

        bottomSheet.delegate = self

        bottomSheet.view.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = bottomSheet.view.heightAnchor.constraint(equalToConstant: 0)
        let leadingConstraint = bottomSheet.view.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(greaterThanOrEqualTo: bottomSheet.view.trailingAnchor)
        let centerConstraint = bottomSheet.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let widthAnchor = bottomSheet.view.widthAnchor.constraint(equalToConstant: maximumWidth)
        widthAnchor.priority = .defaultHigh

        NSLayoutConstraint.activate([
            heightConstraint,
            leadingConstraint,
            trailingConstraint,
            centerConstraint,
            widthAnchor,
            bottomSheet.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setupGestures() {
        dimmView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        if #available(iOS 13.4, *) {
            pan.allowedScrollTypesMask = .continuous
        }
        pan.delegate = self
        bottomSheet.view.addGestureRecognizer(pan)
    }
}

// MARK: - Internal
extension BottomSheetController {
    func animateDismiss(fast: Bool = false, completion: (() -> Void)? = nil) {
        animating = true

        if fast {
            UIView.animate(withDuration: BottomSheetController.dismissalSpeed, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: [.beginFromCurrentState]) { [self] in
                moveContainerBottom()
            } completion: { _ in
                completion?()
            }
        } else {
            UIView.animate(withDuration: BottomSheetController.dismissalSpeed, delay: 0, options: [.beginFromCurrentState]) { [self] in
                moveContainerBottom()
            } completion: { _ in
                completion?()
            }
        }
    }
}

// MARK: - Private
private extension BottomSheetController {
    func moveContainerTop() {
        dimmView.alpha = 1
        heightConstraint.isActive = false
        heightConstraint.constant = min(getContentHeight(), heightLimit)
        heightConstraint.isActive = true
        view.layoutIfNeeded()
        removeMagnification()
        magnifyParent(progress: 1)
    }

    func moveContainerBottom() {
        dimmView.alpha = 0
        heightConstraint.constant = 0
        view.layoutIfNeeded()
        magnifyParent(progress: 0)
    }

    func updateLayout() {
//        let const: CGFloat = traitCollection.horizontalSizeClass == .compact ? 0 : largeScreenSideOffset
//        leadingConstraint.constant = const
//        trailingConstraint.constant = -const

        let contentHeight = getContentHeight()
        guard lastContentHeight != contentHeight
        else { return }

        lastContentHeight = contentHeight

        if layouting { return }
        layouting = true
        baseAnimation(moveContainerTop)
        layouting = false
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
        case .began:
            if let scrollView = bottomSheet.scrollView,
               scrollView.contentOffset.y > -scrollView.safeAreaInsets.top
            {
                scrollView.setContentOffset(.init(x: 0, y: -scrollView.safeAreaInsets.top), animated: true)
            }

            fallthrough
        case .changed:
            dragging = true
            if translation.y > 0 {
                heightConstraint.constant = max(getContentHeight() - translation.y, 0)
            } else {
                let spring = Math.spring(for: translation.y)
                heightConstraint.constant = max(getContentHeight() + spring, 0)
            }

            let progress = min(heightConstraint.constant / getContentHeight(), 1)
            dimmView.alpha = progress
            magnifyParent(progress: progress)
        case .ended:
            let velocity = pan.velocity(in: view)
            let projection = getContentHeight() - translation.y - Math.project(initialVelocity: velocity.y, decelerationRate: UIScrollView.DecelerationRate.normal.rawValue)

            if projection < getContentHeight() / 2 {
                dragging = false
                animateDismiss(fast: true) { [self] in
                    dismiss(animated: false)
                }
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
        guard isMagnificationEnabled else { return }
        guard getContentHeight() >= heightLimit
        else {
            dimmView.transform = CGAffineTransform.identity
            dimmView.layer.cornerRadius = UIScreen.main.displayCornerRadius
            presentingViewController?.view.transform = CGAffineTransform.identity
            presentingViewController?.view.layer.cornerRadius = UIScreen.main.displayCornerRadius
            return
        }

        let magnificationRate = 0.9
        let minimumCornerRadius = 10.0

        let size = (1 - progress) * (1 - magnificationRate) + magnificationRate
        let radius = (UIScreen.main.displayCornerRadius - minimumCornerRadius) * (1 - progress) + minimumCornerRadius
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
}

// MARK: - UIGestureRecognizerDelegate
extension BottomSheetController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer == bottomSheet.scrollView?.panGestureRecognizer
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension BottomSheetController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        BottomSheetControllerAnimator(isPresenting: true, bottomSheet: self)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        BottomSheetControllerAnimator(isPresenting: false, bottomSheet: self)
    }
}
