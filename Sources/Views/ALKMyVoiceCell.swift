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
        sv.contentMode = .scaleAspectFit
        return sv
    }()
    
    fileprivate var stateErrorRemarkView: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        return button
    }()

    var statusViewWidthConst:NSLayoutConstraint?
    var timeLabelRightConst:NSLayoutConstraint?
    
    override func setupViews() {
        super.setupViews()
        
        let width = 245
        
        contentView.addViewsForAutolayout(views: [stateView, stateErrorRemarkView])
        //button action
        stateErrorRemarkView.addTarget(self, action: #selector(stateErrorRemarkViewButtonTouchUpInside(_:)), for: .touchUpInside)
        
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
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 0).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        statusViewWidthConst = stateView.widthAnchor.constraint(equalToConstant: 17)
        statusViewWidthConst?.isActive = true
        
        stateErrorRemarkView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        stateErrorRemarkView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -7).isActive = true
        stateErrorRemarkView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        stateErrorRemarkView.widthAnchor.constraint(equalToConstant:18).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: 0).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        timeLabelRightConst = timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1)
        timeLabelRightConst?.isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

//        if viewModel.isAllRead {
//            stateView.image = UIImage(named: "read_state_3", in: Bundle.applozic, compatibleWith: nil)
//            stateView.tintColor = UIColor(netHex: 0x0578FF)
//        } else if viewModel.isAllReceived {
//            stateView.image = UIImage(named: "read_state_2", in: Bundle.applozic, compatibleWith: nil)
//            stateView.tintColor = UIColor.ALKSVGreyColor153()
//        } else if viewModel.isSent {
//            stateView.image = UIImage(named: "read_state_1", in: Bundle.applozic, compatibleWith: nil)
//            stateView.tintColor = UIColor.ALKSVGreyColor153()
//        } else {
//            stateView.image = UIImage(named: "seen_state_0", in: Bundle.applozic, compatibleWith: nil)
//            stateView.tintColor = UIColor.ALKSVMainColorPurple()
//        }
        self.stateErrorRemarkView.isHidden = true
        self.stateErrorRemarkView.setImage(nil, for: .normal)
        let _svMsgStatus = viewModel.getSVMessageStatus()
        if _svMsgStatus == .sent {
            stateView.image = UIImage(named: "sv_icon_msg_status_sent", in: Bundle.applozic, compatibleWith: nil)
        }else if _svMsgStatus == .error {
            stateView.image = UIImage(named: "sv_icon_msg_status_error", in: Bundle.applozic, compatibleWith: nil)
            self.stateErrorRemarkView.isHidden = false
            self.stateErrorRemarkView.setImage(UIImage(named: "sv_img_msg_status_error", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        }else if _svMsgStatus == .block {
            stateView.image = UIImage(named: "sv_icon_msg_status_block", in: Bundle.applozic, compatibleWith: nil)
            self.stateErrorRemarkView.isHidden = false
            self.stateErrorRemarkView.setImage(UIImage(named: "sv_img_msg_status_block", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        }else{//processing
            stateView.image = UIImage(named: "sv_icon_msg_status_processing", in: Bundle.applozic, compatibleWith: nil)
        }
        
        stateView.isHidden = self.systemConfig?.hideConversationBubbleState ?? false
        if stateView.isHidden {
            stateView.image = nil
            timeLabelRightConst?.constant = 0
            statusViewWidthConst?.constant = 0
        }else{
            timeLabelRightConst?.constant = -1
            statusViewWidthConst?.constant = 15
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
    
    //button action
    @objc private func stateErrorRemarkViewButtonTouchUpInside(_ selector: UIButton) {
        var _isError = false
        var _isViolate = false
        if let _svMsgStatus = self.viewModel?.getSVMessageStatus() {
            _isError = _svMsgStatus == .error
            _isViolate = _svMsgStatus == .block
        }
        ALKConfiguration.delegateConversationRequestInfo?.messageStateRemarkButtonClicked(isError: _isError, isViolate: _isViolate)
    }
}
