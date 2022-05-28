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
        // Do any additional setup after loading the view.
    }

    @IBAction func showBottomSheet(_ sender: Any) {
//        let vc = CalendarController()
        let vc = ScrollController()
        let bs = BottomSheetController(rootViewController: vc, with: .init(withDragger: true, withNavigationBar: true))
        present(bs, animated: true)
    }

}

