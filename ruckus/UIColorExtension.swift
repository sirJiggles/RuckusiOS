//
//  UIColorExtension.swift
//  ruckus
//
//  Created by Gareth on 24/02/2017.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import UIKit


extension UIColor {
    // Ability to use hex init method
    convenience init(r: Int, g: Int, b: Int) {
        assert(r >= 0 && r <= 255, "Invalid red component")
        assert(g >= 0 && g <= 255, "Invalid green component")
        assert(b >= 0 && b <= 255, "Invalid blue component")
    
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }

    convenience init(netHex:Int) {
        self.init(r:(netHex >> 16) & 0xff, g:(netHex >> 8) & 0xff, b:netHex & 0xff)
    }
    
    // System colors
    static var textWhite: UIColor {
        return UIColor(netHex: 0xD8D8D8)
    }
    static var backgroundGrey: UIColor {
        return UIColor(netHex: 0x333333)
    }
    static var lightWhite: UIColor {
        return UIColor(netHex: 0xaaaaaa)
    }
    
    // shades of black darkest(one) -> lightest(two ...)
    static var blackSeven: UIColor {
        return UIColor(netHex: 0x444444)
    }
    static var blackSix: UIColor {
        return UIColor(netHex: 0x3C3C3D)
    }
    static var blackFive: UIColor {
        return UIColor(netHex: 0x232323)
    }
    static var blackFour: UIColor {
        return UIColor(netHex: 0x1C1C1D)
    }
    static var blackThree: UIColor {
        return UIColor(netHex: 0x171717)
    }
    static var blackTwo: UIColor {
        return UIColor(netHex: 0x161616)
    }
    static var blackOne: UIColor {
        return UIColor(netHex: 0x0C0C0C)
    }
    
    // shades of grey
    static var greyOne: UIColor {
        return UIColor(netHex: 0x3D3D3D)
    }
    static var greyTwo: UIColor {
        return UIColor(netHex: 0x868686)
    }
    static var greyThree: UIColor {
        return UIColor(netHex: 0x9F9F9F)
    }
    static var greyFour: UIColor {
        return UIColor(netHex: 0xE7E7E7)
    }
    
    //// Blues
    static var lightestBlue: UIColor {
        return UIColor(netHex: 0x4773A3)
    }
    static var lightBlue: UIColor {
        return UIColor(netHex: 0x2B5E96)
    }
    static var standardBlue: UIColor {
        return UIColor(netHex: 0x154881)
    }
    static var darkBlue: UIColor {
        return UIColor(netHex: 0x09376A)
    }
    static var darkestBlue: UIColor {
        return UIColor(netHex: 0x04284F)
    }
    
    
    // Oranges
    static var lightestOrange: UIColor {
        return UIColor(netHex: 0xFABE61)
    }
    static var lightOrange: UIColor {
        return UIColor(netHex: 0xE6A034)
    }
    static var standardOrange: UIColor {
        return UIColor(netHex: 0xC67F12)
    }
    static var darkOrange: UIColor {
        return UIColor(netHex: 0xA26302)
    }
    static var darkestOrange: UIColor {
        return UIColor(netHex: 0x7A4A00)
    }
    static var theOrange: UIColor {
        return UIColor(netHex: 0xC65312)
    }
    
    // Greens
    static var lightestGreen: UIColor {
        return UIColor(netHex: 0x3FA488)
    }
    static var lightGreen: UIColor {
        return UIColor(netHex: 0x229776)
    }
    static var standardGreen: UIColor {
        return UIColor(netHex: 0x0C8261)
    }
    static var darkGreen: UIColor {
        return UIColor(netHex: 0x016A4D)
    }
    static var darkestGreen: UIColor {
        return UIColor(netHex: 0x00503A)
    }
    
}
