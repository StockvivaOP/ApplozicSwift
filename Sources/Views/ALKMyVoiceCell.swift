//
//  ALKMyVoiceCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

import UIKit
import Foundation
import Kingfisher
import AVFoundation

class ALKMyVoiceCell: ALKVoiceCell {

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    var statusViewWidthConst:NSLayoutConstraint?
    var timeLabelRightConst:NSLayoutConstraint?
    
    override func setupViews() {
        super.setupViews()
        
        let width = 245
        
        contentView.addViewsForAutolayout(views: [stateView])
        
        soundPlayerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        soundPlayerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        soundPlayerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        soundPlayerView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        //        soundPlayerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -7).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
        bubbleView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        statusViewWidthConst = stateView.widthAnchor.constraint(equalToConstant: 17)
        statusViewWidthConst?.isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: 0).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        timeLabelRightConst = timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -6)
        timeLabelRightConst?.isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        if viewModel.isAllRead {
            stateView.image = UIImage(named: "read_state_3", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor(netHex: 0x0578FF)
        } else if viewModel.isAllReceived {
            stateView.image = UIImage(named: "read_state_2", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.ALKSVGreyColor153()
        } else if viewModel.isSent {
            stateView.image = UIImage(named: "read_state_1", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.ALKSVGreyColor153()
        } else {
            stateView.image = UIImage(named: "seen_state_0", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.ALKSVMainColorPurple()
        }
        
        stateView.isHidden = self.systemConfig?.hideConversationBubbleState ?? false
        if stateView.isHidden {
            timeLabelRightConst?.constant = 0
            statusViewWidthConst?.constant = 0
        }else{
            timeLabelRightConst?.constant = -6
            statusViewWidthConst?.constant = 17
        }
    }

    override class func bottomPadding() -> CGFloat {
        return 6
    }

    override func setupStyle() {
        super.setupStyle()
//        if(ALKMessageStyle.sentBubble.style == .edge) {
//            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//        } else {
//            soundPlayerView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.tintColor = ALKMessageStyle.sentBubble.color
//            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
//            soundPlayerView.backgroundColor = ALKMessageStyle.sentBubble.color
//        }
        soundPlayerView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: false)
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let heigh: CGFloat
        heigh = 52
        //10(top pedding) + height(voic content) + 25(statusLabel)
        return 10+heigh+25
    }
}
