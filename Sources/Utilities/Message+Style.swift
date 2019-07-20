//
//  Message+Style.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
public enum ALKMessageStyle {

    public static var displayName = Style(
        font: UIFont.systemFont(ofSize: 14, weight: .medium),
        text: UIColor.ALKSVOrangeColor()
    )

    public static var playTime = Style(
        font: UIFont.systemFont(ofSize: 11, weight: .medium),
        text: UIColor.ALKSVGreyColor102()
    )

    public static var time = Style(
        font: UIFont.systemFont(ofSize: 11, weight: .medium),
        text: UIColor.ALKSVGreyColor153()
    )

    // Received message text style
    public static var receivedMessage = Style(
        font: UIFont.systemFont(ofSize: 16, weight: .medium),
        text: UIColor.ALKSVPrimaryDarkGrey()
    )

    // Sent message text style
    public static var sentMessage = Style(
        font: UIFont.systemFont(ofSize: 16, weight: .medium),
        text: UIColor.ALKSVPrimaryDarkGrey()
    )

    @available(*, deprecated, message: "Use `receivedMessage` and `sentMessage`")
    public static var message = Style(
        font: UIFont.systemFont(ofSize: 16, weight: .medium),
        text: UIColor.ALKSVPrimaryDarkGrey()
    ) {
        didSet {
            receivedMessage = message
            sentMessage = message
        }
    }

    public enum BubbleStyle {
        case edge
        case round
    }

    public struct Bubble {

        /// Message bubble's background color.
        public var color: UIColor

        /// Message bubble corner Radius
        public var cornerRadius:CGFloat

        /// BubbleStyle of the message bubble.
        public var style: BubbleStyle

        /// Width padding which will be used for message view's
        /// right and left padding.
        public let leftPadding: CGFloat
        public let widthPadding: CGFloat

        public init(color: UIColor, style: BubbleStyle) {
            self.color = color
            self.style = style
            self.widthPadding = 7.0
            self.leftPadding = 7.0
            self.cornerRadius = 12
        }
    }

    public static var sentBubble = Bubble(color: UIColor(netHex: 0xFFFFFF), style: .edge)//0xF1F0F0
    public static var receivedBubble = Bubble(color: UIColor(netHex: 0xFFFFFF), style: .edge)
}
