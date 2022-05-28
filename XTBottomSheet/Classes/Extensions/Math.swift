//
//  Math.swift
//  XTBottomSheet
//
//  Created by Даниил Виноградов on 24.05.2022.
//

import UIKit

func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
  return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
}
