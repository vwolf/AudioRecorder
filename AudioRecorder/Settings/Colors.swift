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
        case background_item
        case background_item_light
        case statusbar
        case background_main
        case seperatorline
        case baseGreen
        case baseRed
        case text_01
        case text_02
        
        func toUIColor() -> UIColor {
            switch self {
            case .background:
                return UIColor(red: 0x21/255, green: 0x20/255, blue: 0x1f/255, alpha: 1.0)
            case .background_item:
                return UIColor(red: 0x38/255, green: 0x38/255, blue: 0x38/255, alpha: 1.0)
            case .background_item_light:
                return UIColor(red: 0x5f/255, green: 0x60/255, blue: 0x5d/255, alpha: 1.0)
            case .statusbar:
                return UIColor(red: 0x2c/255, green: 0x46/255, blue: 0x53/255, alpha: 1.0)
            case .background_main:
                return UIColor(red: 0x91/255, green: 0xbc/255, blue: 0xa8/255, alpha: 1.0)
            case .seperatorline:
                return UIColor(red: 0xe8/255, green: 0xdf/255, blue: 0xc7/255, alpha: 1.0)
            case .baseGreen:
                return UIColor(red: 0xac/255, green: 0xba/255, blue: 0x2f/255, alpha: 1.0)
            case .baseRed:
                return UIColor(red: 0xd9/255, green: 0x23/255, blue: 0x1a/255, alpha: 1.0)
            case .text_01:
                return UIColor(red: 0xfa/255, green: 0xfa/255, blue: 0xfa/255, alpha: 1.0)
            case .text_02:
                return UIColor(red: 0xe9/255, green: 0xdd/255, blue: 0xc7/255, alpha: 1.0)
            }
        }
        
//        func toCGColor() -> CGColor {
//            switch self {
//            case .background:
//                return CGColor(red: 0x21, green: 0x20/255, blue: 0x1f/255, alpha: 1.0)
//                <#code#>
//            default:
//                <#code#>
//            }
//        }

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
    
    enum AVModal {
        case background
        case textColor
        
        func toUIColor() -> UIColor {
            switch  self {
            case .background :
                return UIColor(red: 0x0f/255, green: 0x16/255, blue: 0x26/255, alpha: 1.0)
            case .textColor :
                return UIColor(red: 0xf5/255, green: 0xf5/255, blue: 0xf5/255, alpha: 1.0)
            }
        }
    }
}
