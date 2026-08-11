import SwiftUI
import UIKit

// 三噸以上固定式起重機考照學習系統｜iOS Color Tokens
extension Color {
    static let cranePrimaryBlue   = Color(uiColor: .cranePrimaryBlue)
    static let craneSupportBlue   = Color(uiColor: .craneSupportBlue)
    static let craneAccentOrange  = Color(uiColor: .craneAccentOrange)
    static let craneSuccessGreen  = Color(uiColor: .craneSuccessGreen)
    static let craneNeutralDark   = Color(uiColor: .craneNeutralDark)
    static let craneNeutralGray   = Color(uiColor: .craneNeutralGray)
    static let craneBackground    = Color(uiColor: .craneBackground)
    static let craneBorder        = Color(uiColor: .craneBorder)
}

extension UIColor {
    static let cranePrimaryBlue = adaptive(
        light: (30, 107, 255),
        dark: (77, 163, 255)
    )
    static let craneSupportBlue = adaptive(
        light: (77, 163, 255),
        dark: (115, 185, 255)
    )
    static let craneAccentOrange = adaptive(
        light: (255, 138, 0),
        dark: (255, 159, 10)
    )
    static let craneSuccessGreen = adaptive(
        light: (34, 197, 94),
        dark: (48, 209, 88)
    )
    static let craneNeutralDark = adaptive(
        light: (31, 41, 55),
        dark: (249, 250, 251)
    )
    static let craneNeutralGray = adaptive(
        light: (107, 114, 128),
        dark: (180, 187, 198)
    )
    static let craneBackground = adaptive(
        light: (243, 246, 250),
        dark: (0, 0, 0)
    )
    static let craneBorder = adaptive(
        light: (229, 234, 241),
        dark: (58, 58, 60)
    )

    private static func adaptive(
        light: (red: CGFloat, green: CGFloat, blue: CGFloat),
        dark: (red: CGFloat, green: CGFloat, blue: CGFloat)
    ) -> UIColor {
        UIColor { traits in
            let components = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: components.red / 255,
                green: components.green / 255,
                blue: components.blue / 255,
                alpha: 1
            )
        }
    }
}
