//
//  BottomSheetController+Config.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 30.05.2022.
//

import UIKit

public extension BottomSheetController {
    struct Config {
        var withDragger: Bool
        var withNavigationBar: Bool
        var withParentMagnification: Bool

        public init(withDragger: Bool = true, withNavigationBar: Bool = true, withParentMagnification: Bool = false) {
            self.withDragger = withDragger
            self.withNavigationBar = withNavigationBar
            self.withParentMagnification = withParentMagnification
        }
    }
}
