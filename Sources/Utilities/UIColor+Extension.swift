//
//  UIColor+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

import UIKit

public extension UIColor {
    //tag: stockviva
    static func makeColotRGBA(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
    }
    
    //0xAARRGGBB
    static func hex8(_ netHex:Int64) -> UIColor {
        let shiftedRed = netHex >> 16
        let redBits = shiftedRed & 0xff

        let shiftedGreen = netHex >> 8
        let greenBits = shiftedGreen & 0xff

        let shiftedBlue = netHex
        let blueBits = shiftedBlue & 0xff

        let alpha = CGFloat((netHex >> 24) & 0xff)
        return UIColor(red:Int(redBits), green:Int(greenBits), blue:Int(blueBits)).withAlphaComponent(alpha/255.0)
    }

    static func mainRed() -> UIColor {
        return UIColor.init(netHex: 0xE00909)
    }

    static func borderGray() -> UIColor {
        return UIColor.init(netHex: 0xDBDFE2)
    }

    static func lineBreakerProfile() -> UIColor {
        return UIColor.init(netHex: 0xEAEAEA)
    }

    static func circleChartStartPointRed() -> UIColor {
        return UIColor.init(netHex: 0xCE0A11)
    }

    static func circleChartGray() -> UIColor {
        return UIColor.init(netHex: 0xCCCCCC)
    }

    static func circleChartPurple() -> UIColor {
        return UIColor.init(netHex: 0x350064)
    }

    static func circleChartTextColor() -> UIColor {
        return UIColor.init(netHex: 0x666666)
    }

    static func placeholderGray() -> UIColor {
        return UIColor.init(netHex: 0xCCCCCC)
    }

    static func disabledButton() -> UIColor {
        return UIColor.init(netHex: 0xCCCCCC)
    }

    static func onlineGreen() -> UIColor {
        return UIColor.init(netHex: 0x0EB04B)
    }

    static func navigationOceanBlue() -> UIColor {
        return UIColor.init(netHex: 0xECEFF1)
    }

    static func navigationTextOceanBlue() -> UIColor {
        return UIColor.init(netHex: 0x19A5E4)
    }
    
    //tag: stockviva
    static func SVMainColorPurple()-> UIColor {
        return UIColor.makeColotRGBA(red:118, green: 85, blue: 255)
    }
    
    static func SVStockColorRed()-> UIColor {
        return UIColor.makeColotRGBA(red:248, green: 70, blue: 92)
    }
    
    static func SVGreyColor102()-> UIColor {
        return UIColor.makeColotRGBA(red:102, green: 102, blue: 102)
    }
    
    static func SVGreyColor245()-> UIColor {
        return UIColor.makeColotRGBA(red:245, green: 245, blue: 245)
    }
    
    static func SVGreyColor207()-> UIColor {
        return UIColor.makeColotRGBA(red:207, green: 207, blue: 207)
    }
    
    static func SVGreyColor153()-> UIColor {
        return UIColor.makeColotRGBA(red:153, green: 153, blue: 153)
    }
}
