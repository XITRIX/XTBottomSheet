//
//  Math.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

class Math {
    // Calculate position projection
    static func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
    }

    // Calculate spring effect for translation
    static func spring(for translation: CGFloat) -> CGFloat {
        log2(-translation / 30 + 1) * 3
    }
}
