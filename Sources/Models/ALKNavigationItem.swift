//
//  ALKNavigationItems.swift
//  ApplozicSwift
//
//  Created by apple on 28/06/19.
//

import Foundation

public struct ALKNavigationItem{
    public var buttonImage : UIImage?
    public var buttonText : String?
    public var identifier : String

    /// ALKNavigationItem init method for creating Navigation item
    /// buttonImage will have first priority in case if you have passed buttonImage and buttonText both
    /// - Parameters:
    ///   - identifier: identifier for notification for which button is clicked
    ///   - buttonImage: Pass UIImage in case if  you want to show the image in Navigation bar
    ///   - buttonText: Pass text in case if you want to show text in Navigation bar

    public init(identifier: String, buttonImage: UIImage?, buttonText : String?) {
        self.identifier = identifier
        self.buttonImage = buttonImage
        self.buttonText = buttonText
    }
}
