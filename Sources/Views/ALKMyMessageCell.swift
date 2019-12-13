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
        sv.contentMode = .scaleAspectFit
        return sv
    }()
    
    fileprivate var stateErrorRemarkView: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        return button
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
            static let bottom: CGFloat = 5.0
            static let height: CGFloat = 20.0
            static let maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude
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
            static let left: CGFloat = 110.0
            static let right: CGFloat = 7.0
        }

        struct TimeLabel {
            static let top: CGFloat = 0
            static let right: CGFloat = 1
            static let height: CGFloat = 15
        }
        
        struct StateView {
            static let height: CGFloat = 15.0
            static let width: CGFloat = 15.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5
            static let right: CGFloat = 0.0
        }
        
        struct  StateErrorRemarkView {
            static let right: CGFloat = 7
            static let height: CGFloat = 18
            static let width: CGFloat = 18
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
    }
    var replyViewTopConst:NSLayoutConstraint?
    var replyViewInnerTopConst:NSLayoutConstraint?
    var replyViewInnerImgTopConst:NSLayoutConstraint?
    var replyViewInnerImgBottomConst:NSLayoutConstraint?
    var replyMsgViewBottomConst:NSLayoutConstraint?
    var statusViewWidthConst:NSLayoutConstraint?
    var timeLabelRightConst:NSLayoutConstraint?
    var emailViewTopConst:NSLayoutConstraint?

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [stateView, stateErrorRemarkView])
        //button action
        stateErrorRemarkView.addTarget(self, action: #selector(stateErrorRemarkViewButtonTouchUpInside(_:)), for: .touchUpInside)
        
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
        replyMsgViewBottomConst = replyMessageLabel.bottomAnchor.constraint(equalTo: replyView.bottomAnchor, constant: -Padding.ReplyMessageLabel.bottom)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: Padding.BubbleView.top),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: Padding.BubbleView.left),
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right),
            
            stateErrorRemarkView.centerYAnchor.constraint(
                equalTo: bubbleView.centerYAnchor),
            stateErrorRemarkView.trailingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: -Padding.StateErrorRemarkView.right),
            stateErrorRemarkView.heightAnchor.constraint(equalToConstant: Padding.StateErrorRemarkView.height),
            stateErrorRemarkView.widthAnchor.constraint(equalToConstant:Padding.StateErrorRemarkView.width),

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
            replyMessageLabel.heightAnchor.constraintLessThanOrEqualToAnchor(constant: 0,
                                                                             identifier: ConstraintIdentifier.ReplyMessageLabel.height),
            replyMsgViewBottomConst!,
            
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

    open func update(viewModel: ALKMessageViewModel, replyMessage: ALKMessageViewModel?) {
        super.update(viewModel: viewModel, style: ALKMessageStyle.sentMessage, replyMessage: replyMessage)
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
        
        //reply view
        if viewModel.getDeletedMessageInfo().isDeleteMessage {
            handleReplyView(replyMessage: nil)
        }else{
            handleReplyView(replyMessage: replyMessage)
        }
        
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
            timeLabelRightConst?.constant = -Padding.TimeLabel.right
            statusViewWidthConst?.constant = Padding.StateView.width
        }
    }

    class func rowHeigh(viewModel: ALKMessageViewModel,
                        width: CGFloat,
                        replyMessage: ALKMessageViewModel?) -> CGFloat {
        let _isDeletedMsg = viewModel.getDeletedMessageInfo().isDeleteMessage
        
        let leftSpacing = Padding.BubbleView.left + ALKMessageStyle.sentBubble.leftPadding
        let rightSpacing = Padding.BubbleView.right + ALKMessageStyle.sentBubble.widthPadding /*+ bubbleViewRightPadding*/
        
        var heightPadding = Padding.BubbleView.top + Padding.ReplyView.top + Padding.MessageView.bottom + Padding.StateView.top + Padding.StateView.height + Padding.StateView.bottom
        
        /// Calculating messageHeight
        let messageWidth = width - (leftSpacing + rightSpacing)
        var messageHeight:CGFloat = 0.0
        if _isDeletedMsg {
            messageHeight = super.messageHeight(viewModel: viewModel, width: messageWidth, font: ALKMessageStyle.deletedMessage.font)
        }else{
            messageHeight = super.messageHeight(viewModel: viewModel, width: messageWidth, font: ALKMessageStyle.receivedMessage.font)
            
            if viewModel.isReplyMessage {
                heightPadding += Padding.MessageView.top
            }
        }
        
        let totalHeight = messageHeight + heightPadding
        guard replyMessage != nil && _isDeletedMsg == false else { return totalHeight }
        //add reply view height
        //get width
        let _haveMsgIcon = [ALKMessageType.voice, ALKMessageType.video, ALKMessageType.photo, ALKMessageType.document].contains(replyMessage!.messageType)
        let (url, image) = ReplyMessageImage().previewFor(message: replyMessage!)
        let _havePreviewImage = url != nil || image != nil
        
        var _maxMsgWidth = messageWidth - (Padding.ReplyView.left + Padding.ReplyView.right + Padding.ReplyIndicatorView.width + Padding.ReplyMessageTypeImageView.left + Padding.ReplyMessageLabel.right + Padding.PreviewImageView.right)
        if _haveMsgIcon {
            _maxMsgWidth -= Padding.ReplyMessageTypeImageView.width + Padding.ReplyMessageLabel.left
        }
        if _havePreviewImage {
            _maxMsgWidth -= Padding.PreviewImageView.width
        }
        var _replyMsgContent:String? = ""
        switch replyMessage!.messageType {
        case .text, .html:
            _replyMsgContent = replyMessage!.message
        default:
            _replyMsgContent = replyMessage!.messageType.rawValue
        }
        let _replyViewHeightInfo = ALKMessageCell.getReplyViewHeight(Padding.ReplyView.height, defaultMsgHeight: Padding.ReplyMessageLabel.height, maxMsgHeight: Padding.ReplyMessageLabel.maxHeight, maxMsgWidth:_maxMsgWidth, replyMessageContent: _replyMsgContent)
        
        
        return totalHeight + _replyViewHeightInfo.replyViewHeight
    }

    private func handleReplyView(replyMessage: ALKMessageViewModel?) {
        guard let replyMessage = replyMessage else {
            self.emailViewTopConst?.constant = 0
            showReplyView(false, haveImageType: false, haveImage: false)
            return
        }
        //get setting
        let _haveMsgIcon = [ALKMessageType.voice, ALKMessageType.video, ALKMessageType.photo, ALKMessageType.document].contains(replyMessage.messageType)
        let (url, image) = ReplyMessageImage().previewFor(message: replyMessage)
        let _havePreviewImage = url != nil || image != nil
        
        self.emailViewTopConst?.constant = Padding.MessageView.top
        if replyMessage.messageType == .text || replyMessage.messageType == .html {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = 0
        } else {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = Padding.PreviewImageView.width
        }
        showReplyView(true, haveImageType: _haveMsgIcon, haveImage: _havePreviewImage)
    }

    fileprivate func showReplyView(_ show: Bool, haveImageType:Bool, haveImage:Bool) {
        //get width
        let leftSpacing = Padding.BubbleView.left + ALKMessageStyle.sentBubble.widthPadding
        let rightSpacing = Padding.BubbleView.right /*+ ALKMessageStyle.sentBubble.widthPadding + ( ALKMessageStyle.sentBubble.style == .edge ? 5 : 0 )*/
        
        var _maxMsgWidth = self.contentView.bounds.size.width - (leftSpacing + rightSpacing) - (Padding.ReplyView.left + Padding.ReplyView.right + Padding.ReplyIndicatorView.width + Padding.ReplyMessageTypeImageView.left + Padding.ReplyMessageLabel.right + Padding.PreviewImageView.right)
        if haveImageType {
            _maxMsgWidth -= Padding.ReplyMessageTypeImageView.width + Padding.ReplyMessageLabel.left
        }
        if haveImage{
            _maxMsgWidth -= Padding.PreviewImageView.width
        }
        let _replyViewHeightInfo = ALKMessageCell.getReplyViewHeight(Padding.ReplyView.height, defaultMsgHeight: Padding.ReplyMessageLabel.height, maxMsgHeight: Padding.ReplyMessageLabel.maxHeight, maxMsgWidth:_maxMsgWidth, replyMessageContent: self.replyMessageLabel.text)
            
        //set constraint
        replyView
            .constraint(withIdentifier: ConstraintIdentifier.replyViewHeightIdentifier)?
            .constant = show ? _replyViewHeightInfo.replyViewHeight : 0
        replyNameLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyNameLabel.height)?
            .constant = show ? Padding.ReplyNameLabel.height : 0
        replyMessageLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyMessageLabel.height)?
            .constant = show ? _replyViewHeightInfo.replyMsgViewHeight : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.height)?
            .constant = haveImage ? Padding.PreviewImageView.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?
            .constant = haveImage ? Padding.PreviewImageView.width : 0
        replyMessageTypeImageView
            .constraint(withIdentifier: ConstraintIdentifier.replyMessageTypeImageViewHeight)?
            .constant = haveImageType ? Padding.ReplyMessageTypeImageView.height : 0
        
        //paddnig
        replyViewTopConst?.constant = show ? Padding.ReplyView.top : 0
        replyViewInnerTopConst?.constant = show ? Padding.ReplyNameLabel.top : 0
        replyViewInnerImgTopConst?.constant = show ? Padding.PreviewImageView.top : 0
        replyViewInnerImgBottomConst?.constant = show ? -Padding.PreviewImageView.bottom : 0
        replyMsgViewBottomConst?.constant = show ? -Padding.ReplyMessageLabel.bottom : 0
        
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
