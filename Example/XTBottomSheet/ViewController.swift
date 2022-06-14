//
//  ViewController.swift
//  XTBottomSheet
//
//  Created by Daniil Vinogradov on 05/28/2022.
//  Copyright (c) 2022 Daniil Vinogradov. All rights reserved.
//

import UIKit
import XTBottomSheet

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.tintAdjustmentMode = .dimmed
    }

    @IBAction func showBottomSheet(_ sender: Any) {
        let vc = CalendarController()
//        let vc = ScrollController()
        let bs = BottomSheetController(rootViewController: vc, with: .init(withDragger: true, withNavigationBar: true, withParentMagnification: true))
        present(bs, animated: true)
    }

    @IBAction func presentModalAction(_ sender: Any) {
        let vc = ScrollController()
        vc.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }

        present(vc, animated: true)
    }
}

class CustomView: UIView {
    override func tintColorDidChange() {
        super.tintColorDidChange()
    }
}
