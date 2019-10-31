//
//  ALKMyPhotoLandscapeCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
// MARK: - ALKMyPhotoLandscapeCell
class ALKMyPhotoLandscapeCell: ALKPhotoCell {
    
    enum State {
        case upload
        case uploading
        case uploaded
    }
    
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
    
    struct Padding {
        struct PhotoView {
            static let right: CGFloat = 14
            static let top: CGFloat = 6
        }
    }
    
    var statusViewWidthConst:NSLayoutConstraint?
    var timeLabelRightConst:NSLayoutConstraint?
    
    override class var messageTextFont: UIFont {
        return ALKMessageStyle.sentMessage.font
    }
    
    override func setupViews() {
        super.setupViews()
        
        contentView.addViewsForAutolayout(views: [stateView, stateErrorRemarkView])
        //button action
        stateErrorRemarkView.addTarget(self, action: #selector(stateErrorRemarkViewButtonTouchUpInside(_:)), for: .touchUpInside)
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -7).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: ALKPhotoCell.maxWidth*ALKPhotoCell.widthPercentage).isActive = true
        bubbleView.heightAnchor.constraint(equalToConstant: (ALKPhotoCell.maxWidth*ALKPhotoCell.heightPercentage) + 7).isActive = true
        
        photoView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0).isActive = true
        photoView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 0).isActive = true
        photoView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 0).isActive = true
        
        fileSizeLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -12).isActive = true
        
        stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 0).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        statusViewWidthConst = stateView.widthAnchor.constraint(equalToConstant: 15)
        statusViewWidthConst?.isActive = true
        
        stateErrorRemarkView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        stateErrorRemarkView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -7).isActive = true
        stateErrorRemarkView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        stateErrorRemarkView.widthAnchor.constraint(equalToConstant:18).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: 0).isActive = true
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
        captionLabel.font = ALKMessageStyle.sentMessage.font
        captionLabel.textColor = ALKMessageStyle.sentMessage.text
        if(ALKMessageStyle.sentBubble.style == .edge) {
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        } else {
            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        }
    }
    
    override class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat) -> CGFloat {
        
        var height: CGFloat
        
        height = ceil(width*heightPercentage)
        if let message = viewModel.message, !message.isEmpty {
            height += message.rectWithConstrainedWidth(
                width*widthPercentage,
                font: messageTextFont).height.rounded(.up) + Padding.CaptionLabel.bottom
        }
        
        //10(top padding) + height(photo content) + 34(captionLabel) + 25(statusLabel)
        return 10+height+34+25
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
