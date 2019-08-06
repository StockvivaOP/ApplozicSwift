//
//  ALKMessageCell.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import Applozic

// MARK: - ALKMyMessageCell
open class ALKMyMessageCell: ALKMessageCell {

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    static var bubbleViewRightPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.sentBubble.style == .edge else {
            return ALKMessageStyle.sentBubble.widthPadding
        }
        return ALKMessageStyle.sentBubble.widthPadding + 5
    }()

    struct Padding {
        struct ReplyView {
            static let left: CGFloat = 7.0
            static let right: CGFloat = 7.0
            static let top: CGFloat = 7.0
            static let height: CGFloat = 50.0
        }
        
        struct ReplyIndicatorView {
            static let width: CGFloat = 4.0
            static let height: CGFloat = 50.0
        }
        
        struct ReplyNameLabel {
            static let top: CGFloat = 5.0
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let height: CGFloat = 20.0
        }
        
        struct ReplyMessageTypeImageView {
            static let left: CGFloat = 5.0
            static let width: CGFloat = 20.0
            static let height: CGFloat = 20.0
        }
        
        struct ReplyMessageLabel {
            static let left: CGFloat = 5.0
            static let right: CGFloat = 20.0
            static let top: CGFloat = 0.0
            static let height: CGFloat = 20.0
        }
        
        struct PreviewImageView {
            static let height: CGFloat = 40.0
            static let width: CGFloat = 48.0
            static let right: CGFloat = 9.5
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5.0
        }
        
        struct MessageView {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 7
            static let left: CGFloat = 7
        }

        struct BubbleView {
            static let top: CGFloat = 10
            static let left: CGFloat = 95.0
            static let right: CGFloat = 7.0
        }

        struct TimeLabel {
            static let top: CGFloat = 0
            static let right: CGFloat = 6
            static let height: CGFloat = 15
        }
        
        struct StateView {
            static let height: CGFloat = 15.0
            static let width: CGFloat = 17.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5
            static let right: CGFloat = 8.0
        }
    }


    struct ConstraintIdentifier {
        struct ReplyNameLabel {
            static let height = "ReplyNameHeight"
        }
        struct ReplyMessageLabel {
            static let height = "ReplyMessageHeight"
        }
        struct PreviewImage {
            static let height = "ReplyPreviewImageHeight"
            static let width = "ReplyPreviewImageWidth"
        }
        static let replyViewHeightIdentifier = "ReplyViewHeight"
        static let replyMessageTypeImageViewHeight = "replyMessageTypeImageViewHeight"
        static let replyIndicatorViewHeight = "replyIndicatorViewHeight"
    }
    var replyViewTopConst:NSLayoutConstraint?
    var replyViewInnerTopConst:NSLayoutConstraint?
    var replyViewInnerImgTopConst:NSLayoutConstraint?
    var replyViewInnerImgBottomConst:NSLayoutConstraint?
    var statusViewWidthConst:NSLayoutConstraint?
    var timeLabelRightConst:NSLayoutConstraint?
    var emailViewTopConst:NSLayoutConstraint?

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [stateView])
        
        replyViewTopConst = replyView.topAnchor.constraint(
            equalTo: bubbleView.bottomAnchor,
            constant: Padding.ReplyView.top)
        replyViewInnerTopConst = replyNameLabel.topAnchor.constraint(
            equalTo: replyView.topAnchor,
            constant: Padding.ReplyNameLabel.top)
        replyViewInnerImgTopConst = previewImageView.topAnchor.constraint(
            equalTo: replyView.topAnchor,
            constant: Padding.PreviewImageView.top)
        replyViewInnerImgBottomConst = previewImageView.bottomAnchor.constraint(
            lessThanOrEqualTo: replyView.bottomAnchor,
            constant: -Padding.PreviewImageView.bottom)
        replyMessageTypeImagewidthConst = replyMessageTypeImageView.widthAnchor.constraint(equalToConstant: Padding.ReplyMessageTypeImageView.width)
        replyMessageLabelConst = replyMessageLabel.leadingAnchor.constraint(
            equalTo: replyMessageTypeImageView.trailingAnchor,
            constant: Padding.ReplyMessageLabel.left)
        statusViewWidthConst = stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width)
        timeLabelRightConst = timeLabel.trailingAnchor.constraint(
            equalTo: stateView.leadingAnchor,
            constant: -Padding.TimeLabel.right)
        emailViewTopConst = emailTopView.topAnchor.constraint(
            equalTo: replyView.bottomAnchor,
            constant: Padding.MessageView.top)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: Padding.BubbleView.top),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: Padding.BubbleView.left),
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right),

            replyView.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: Padding.ReplyView.top),
            replyView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyViewHeightIdentifier),
            replyView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.ReplyView.left),
            replyView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.ReplyView.right),
            
            replyIndicatorView.topAnchor.constraint(
                equalTo: replyView.topAnchor),
            replyIndicatorView.leadingAnchor.constraint(
                equalTo: replyView.leadingAnchor),
            replyIndicatorView.bottomAnchor.constraint(
                equalTo: replyView.bottomAnchor),
            replyIndicatorView.widthAnchor.constraint(equalToConstant: Padding.ReplyIndicatorView.width),
            replyIndicatorView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyIndicatorViewHeight),

            replyViewInnerImgTopConst!,
            previewImageView.trailingAnchor.constraint(
                lessThanOrEqualTo: replyView.trailingAnchor,
                constant: -Padding.PreviewImageView.right),
            replyViewInnerImgBottomConst!,
            previewImageView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.PreviewImage.height),
            previewImageView.widthAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.PreviewImage.width),
            
            replyNameLabel.leadingAnchor.constraint(
                equalTo:replyIndicatorView.trailingAnchor,
                constant: Padding.ReplyNameLabel.left),
            replyViewInnerTopConst!,
            replyNameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyNameLabel.right),
            replyNameLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.ReplyNameLabel.height),
            
            replyMessageTypeImageView.leadingAnchor.constraint(
                equalTo: replyIndicatorView.trailingAnchor,
                constant: Padding.ReplyMessageTypeImageView.left),
            replyMessageTypeImageView.centerYAnchor.constraint(equalTo: replyMessageLabel.centerYAnchor),
            replyMessageTypeImagewidthConst!,
            replyMessageTypeImageView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyMessageTypeImageViewHeight),
            
            replyMessageLabelConst!,
            replyMessageLabel.topAnchor.constraint(
                equalTo: replyNameLabel.bottomAnchor,
                constant: Padding.ReplyMessageLabel.top),
            replyMessageLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyMessageLabel.right),
            replyMessageLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.ReplyMessageLabel.height),
            
            emailViewTopConst!,
            emailTopView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMessageStyle.receivedBubble.widthPadding),
            emailTopView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKFriendMessageCell.bubbleViewLeftPadding),
            emailTopHeight,

            messageView.topAnchor.constraint(
                equalTo: emailTopView.bottomAnchor),
            messageView.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.MessageView.bottom),
            messageView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMessageStyle.receivedBubble.widthPadding),
            messageView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.MessageView.left),
            
            stateView.topAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: Padding.StateView.top),
            stateView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.StateView.right),
            stateView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Padding.StateView.bottom),
            statusViewWidthConst!,
            stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height),
            
            timeLabel.topAnchor.constraint(
                equalTo: stateView.topAnchor,
                constant: Padding.TimeLabel.top),
            timeLabelRightConst!,
            timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height),
            ])
    }

    open  override func setupStyle() {
        super.setupStyle()
        //messageView.setStyle(ALKMessageStyle.sentMessage)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.tintColor = ALKMessageStyle.sentBubble.color
            bubbleView.image = bubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: false)
        }else{
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.tintColor = ALKMessageStyle.sentBubble.color
            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
        }
    }

    open override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel, style: ALKMessageStyle.sentMessage)
        
        if viewModel.isReplyMessage {
            guard
                let metadata = viewModel.metadata,
                let replyId = metadata[AL_MESSAGE_REPLY_KEY] as? String,
                let actualMessage = getMessageFor(key: replyId)
                else {return}
            showReplyView(true)
            if actualMessage.messageType == .text || actualMessage.messageType == .html {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = 0
            } else {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = Padding.PreviewImageView.width
            }
            self.emailViewTopConst?.constant = Padding.MessageView.top
        } else {
            self.emailViewTopConst?.constant = 0
            showReplyView(false)
        }
        
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
            stateView.image = nil
            timeLabelRightConst?.constant = 0
            statusViewWidthConst?.constant = 0
        }else{
            timeLabelRightConst?.constant = -Padding.TimeLabel.right
            statusViewWidthConst?.constant = Padding.StateView.width
        }
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,
                                 width: CGFloat) -> CGFloat {
        /// Calculating messageHeight
        let leftSpacing = Padding.BubbleView.left + ALKMessageStyle.sentBubble.widthPadding
        let rightSpacing = Padding.BubbleView.right + bubbleViewRightPadding
        let messageWidth = width - (leftSpacing + rightSpacing)
        let messageHeight = super.messageHeight(viewModel: viewModel, width: messageWidth, font: ALKMessageStyle.sentMessage.font)
        var heightPadding = Padding.BubbleView.top + Padding.ReplyView.top + Padding.MessageView.bottom + Padding.StateView.top + Padding.StateView.height + Padding.StateView.bottom
        if viewModel.isReplyMessage {
            heightPadding += Padding.MessageView.top
        }
        
        let totalHeight = messageHeight + heightPadding
        guard
            let metadata = viewModel.metadata,
            let _ = metadata[AL_MESSAGE_REPLY_KEY] as? String
            else {
                return totalHeight
        }
        return totalHeight + Padding.ReplyView.height
    }


    fileprivate func showReplyView(_ show: Bool) {
        replyView
            .constraint(withIdentifier: ConstraintIdentifier.replyViewHeightIdentifier)?
            .constant = show ? Padding.ReplyView.height : 0
        replyNameLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyNameLabel.height)?
            .constant = show ? Padding.ReplyNameLabel.height : 0
        replyMessageLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyMessageLabel.height)?
            .constant = show ? Padding.ReplyMessageLabel.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.height)?
            .constant = show ? Padding.PreviewImageView.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?
            .constant = show ? Padding.PreviewImageView.width : 0
        
        replyMessageTypeImageView
            .constraint(withIdentifier: ConstraintIdentifier.replyMessageTypeImageViewHeight)?
            .constant = show ? Padding.ReplyMessageTypeImageView.height : 0
        replyIndicatorView
            .constraint(withIdentifier: ConstraintIdentifier.replyIndicatorViewHeight)?
            .constant = show ? Padding.ReplyIndicatorView.height : 0
        
        //paddnig
        replyViewTopConst?.constant = show ? Padding.ReplyView.top : 0
        replyViewInnerTopConst?.constant = show ? Padding.ReplyNameLabel.top : 0
        replyViewInnerImgTopConst?.constant = show ? Padding.PreviewImageView.top : 0
        replyViewInnerImgBottomConst?.constant = show ? -Padding.PreviewImageView.bottom : 0
        
        replyView.isHidden = !show
        replyIndicatorView.isHidden = !show
        replyNameLabel.isHidden = !show
        replyMessageTypeImageView.isHidden = !show
        replyMessageLabel.isHidden = !show
        previewImageView.isHidden = !show
    }

    // MARK: - ChatMenuCell
    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if(ALKMessageStyle.sentBubble.style == .edge){
            self.bubbleView.image = bubbleViewImage(for: ALKMessageStyle.sentBubble.style,isReceiverSide:false,showHangOverImage: true)
        }
    }

    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if(ALKMessageStyle.sentBubble.style == .edge){
            self.bubbleView.image =  bubbleViewImage(for: ALKMessageStyle.sentBubble.style,isReceiverSide: false,showHangOverImage: false)
        }
    }
}
