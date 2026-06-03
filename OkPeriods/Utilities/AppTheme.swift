//
//  AppTheme.swift
//  OkPeriods
//
//  Created by Anu on 03/06/26.
//

import UIKit

enum AppTheme {
    static let background = UIColor(red: 0.98, green: 0.95, blue: 0.93, alpha: 1.0)
    static let heroStart = UIColor(red: 0.83, green: 0.42, blue: 0.37, alpha: 1.0)
    static let heroEnd = UIColor(red: 0.96, green: 0.71, blue: 0.62, alpha: 1.0)
    static let surface = UIColor.white
    static let secondarySurface = UIColor(red: 0.99, green: 0.98, blue: 0.97, alpha: 1.0)
    static let primaryText = UIColor(red: 0.19, green: 0.13, blue: 0.16, alpha: 1.0)
    static let secondaryText = UIColor(red: 0.41, green: 0.34, blue: 0.37, alpha: 1.0)
    static let primaryAction = UIColor(red: 0.75, green: 0.31, blue: 0.28, alpha: 1.0)
    static let accent = UIColor(red: 0.99, green: 0.89, blue: 0.84, alpha: 1.0)
    static let border = UIColor(red: 0.93, green: 0.87, blue: 0.84, alpha: 1.0)
    static let success = UIColor(red: 0.18, green: 0.55, blue: 0.40, alpha: 1.0)
    static let danger = UIColor(red: 0.78, green: 0.25, blue: 0.29, alpha: 1.0)
    static let shadow = UIColor.black.withAlphaComponent(0.08)
}

extension UIFont {
    static func roundedStyle(_ textStyle: TextStyle, weight: Weight = .regular) -> UIFont {
        let pointSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        let baseFont = UIFont.systemFont(ofSize: pointSize, weight: weight)
        guard let roundedDescriptor = baseFont.fontDescriptor.withDesign(.rounded) else {
            return baseFont
        }
        return UIFont(descriptor: roundedDescriptor, size: pointSize)
    }
}
