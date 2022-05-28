//
//  BottomSheetContainer.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

protocol BottomSheetContainerDelegate: AnyObject {
    var heightLimit: CGFloat { get }
}

class BottomSheetContainer: UIViewController {
    @IBOutlet var containerView: UIView!
    @IBOutlet var draggerView: UIView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var blurLayer: UIView!

    weak var delegate: BottomSheetContainerDelegate?
    let rootViewController: UIViewController
    let config: BottomSheetController.Config
    var scrollHeightConstraint: NSLayoutConstraint?
    var scrollSizeObserver: NSKeyValueObservation?
    var scrollOffsetObserver: NSKeyValueObservation?

    var scrollView: UIScrollView? {
        rootViewController.view.firstSubview(of: UIScrollView.self)
    }

    var draggerHeigth: CGFloat {
        config.withDragger ? draggerView.frame.height : 0
    }

    var navigationHeight: CGFloat {
        config.withNavigationBar ? navigationBar.frame.height : 0
    }

    init(rootViewController: UIViewController, with config: BottomSheetController.Config) {
        self.config = config
        self.rootViewController = rootViewController
        super.init(nibName: nil, bundle: Bundle(for: Self.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        additionalSafeAreaInsets.top += draggerHeigth + navigationHeight

        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.items = [rootViewController.navigationItem]

        draggerView.isHidden = !config.withDragger
        navigationBar.isHidden = !config.withNavigationBar

        // Setup root controller
        addChild(rootViewController)
        containerView.addSubview(rootViewController.view)
        rootViewController.didMove(toParent: self)

        view.backgroundColor = rootViewController.view.backgroundColor

        rootViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            rootViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            rootViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rootViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        view.layer.cornerRadius = 10
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        preinitScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollHeight()
    }

    func preinitScroll() {
        blurLayer.alpha = 0

        guard let scrollView = scrollView
        else { return }

        scrollView.alwaysBounceVertical = false

        scrollHeightConstraint = scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        scrollHeightConstraint?.isActive = true

        scrollSizeObserver = scrollView.observe(\.contentSize, options: .new) { [unowned self] _, _ in
            updateScrollHeight()
        }

        scrollOffsetObserver = scrollView.observe(\.contentOffset, options: .new) { [weak self] scrollView, offset in
            guard let self = self,
                  let rawOffset = offset.newValue
            else { return }

            let offset = rawOffset.y + scrollView.safeAreaInsets.top
            let progress = min(max(0, offset), 4) / 4
            self.blurLayer.alpha = progress
        }
    }

    func updateScrollHeight() {
        guard let scrollView = scrollView,
              let delegate = delegate
        else { return }

        let limit = delegate.heightLimit
        let safeArea = scrollView.safeAreaInsets
        let scrollSize = scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom + safeArea.top + safeArea.bottom
        scrollHeightConstraint?.constant = min(scrollSize, limit)
    }
}

extension UIView {
    func firstSubview<T>(of type: T.Type) -> T? {
        var iter: UIView? = self

        while iter != nil {
            if let res = iter as? T {
                return res
            }
            iter = iter?.subviews.first
        }

        return nil
    }
}
