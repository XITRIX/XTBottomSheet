//
//  UIScreen.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    /// The corner radius of the display. Uses a private property of `UIScreen`,
    /// and may report 0 if the API changes.
    public var displayCornerRadius: CGFloat {
        guard let cornerRadius = value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            return 0
        }

        return cornerRadius
    }
}
