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
        sv.contentMode = .center
        return sv
    }()
    
    struct Padding {
        struct PhotoView {
            static let right: CGFloat = 14
            static let top: CGFloat = 6
        }
    }
    
    override class var messageTextFont: UIFont {
        return ALKMessageStyle.sentMessage.font
    }
    
    override func setupViews() {
        super.setupViews()
        
        contentView.addViewsForAutolayout(views: [stateView])
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -7).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: ALKPhotoCell.maxWidth*ALKPhotoCell.widthPercentage).isActive = true
        bubbleView.heightAnchor.constraint(equalToConstant: (ALKPhotoCell.maxWidth*ALKPhotoCell.heightPercentage) + 7).isActive = true
        
        photoView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0).isActive = true
        photoView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 0).isActive = true
        photoView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 0).isActive = true
        
        fileSizeLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -12).isActive = true
        
        stateView.isHidden = self.systemConfig?.hideConversationBubbleState ?? false
        if stateView.isHidden {
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8).isActive = true
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
            timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        }else{
            stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
            stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8).isActive = true
            stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
            stateView.widthAnchor.constraint(equalToConstant: 17).isActive = true
            stateView.heightAnchor.constraint(equalToConstant: 15).isActive = true
            
            timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: 0).isActive = true
            timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -6).isActive = true
            timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        }
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
}
