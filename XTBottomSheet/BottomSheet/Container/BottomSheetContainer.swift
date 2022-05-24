//
//  BottomSheetContainer.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

protocol BottomSheetContainerDelegate: AnyObject {
    var heightLimit: CGFloat { get }
    func scrollViewContentSizeChanged()
}

class BottomSheetContainer: UIViewController {
    @IBOutlet var containerView: UIView!

    weak var delegate: BottomSheetContainerDelegate?
    let rootViewController: UIViewController
    var scrollHeightConstraint: NSLayoutConstraint?
    var observer: NSKeyValueObservation?

    var scrollView: UIScrollView? {
        rootViewController.view.firstSubview(of: UIScrollView.self)
    }

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        super.init(nibName: nil, bundle: Bundle.init(for: Self.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        additionalSafeAreaInsets.top += 20

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
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        preinitScroll()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollHeight()
    }

    func preinitScroll() {
        guard let scrollView = scrollView
        else { return }

        scrollView.alwaysBounceVertical = false

        scrollHeightConstraint = scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        scrollHeightConstraint?.isActive = true

        observer = scrollView.observe(\.contentSize, options: .new) { [unowned self] scrollView, size in
            updateScrollHeight()
            delegate?.scrollViewContentSizeChanged()
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
