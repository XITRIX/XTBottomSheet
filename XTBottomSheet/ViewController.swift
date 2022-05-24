//
//  ViewController.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showBottomSheet(_ sender: Any) {
//        let vc = CalendarController()
        let vc = ScrollController()
//        let nvc = UINavigationController(rootViewController: vc)
        let bs = BottomSheetController(rootViewController: vc)
        present(bs, animated: true)
    }

}

