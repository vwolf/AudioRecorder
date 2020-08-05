//
//  Colors.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
}

enum Colors {
    
    enum Base {
        case background
        case statusbar
        case background_main
        case seperatorline
        
        func toUIColor() -> UIColor {
            switch self {
            case .background:
                return UIColor(red: 0x0f/255, green: 0x16/255, blue: 0x26/255, alpha: 1.0)
            case .statusbar:
                return UIColor(red: 0x2c/255, green: 0x46/255, blue: 0x53/255, alpha: 1.0)
            case .background_main:
                return UIColor(red: 0x91/255, green: 0xbc/255, blue: 0xa8/255, alpha: 1.0)
            case .seperatorline:
                return UIColor(red: 0xe8/255, green: 0xdf/255, blue: 0xc7/255, alpha: 1.0)
            }
        }

    }
    
    enum Item {
        case textColor
        case textColorLow
        
        func toUIColor() -> UIColor {
            switch self {
            case .textColor:
                 return UIColor(red: 0xf5/255, green: 0xf5/255, blue: 0xf5/255, alpha: 1.0)
            case .textColorLow:
                return UIColor(red: 0xe9/255, green: 0xdd/255, blue: 0xc7/255, alpha: 1.0)
            
            }
        }
    }
}
