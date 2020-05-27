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
        struct BubbleView {
            static let top: CGFloat = 10
            static let right: CGFloat = 7.0
            static let height: CGFloat = 7.0
        }
        
        struct PhotoView {
            static let top: CGFloat = 5
            static let left: CGFloat = 5
            static let right: CGFloat = 5
        }
        //tag: stockviva start
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
        //tag: stockviva end
        struct FileSizeLabel {
            static let right: CGFloat = 12.0
        }
        
        struct StateView {
            static let right: CGFloat = 0.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5.0
            static let height: CGFloat = 15.0
            static let width: CGFloat = 15.0
        }
        
        struct StateErrorRemarkView {
            static let right: CGFloat = 7.0
            static let height: CGFloat = 18.0
            static let width: CGFloat = 18.0
        }
        
        struct TimeLabel {
            static let right: CGFloat = 1.0
            static let top: CGFloat = 0.0
            static let height: CGFloat = 15.0
        }
    }
    
    //tag: stockviva start
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
    var photoViewTopConst:NSLayoutConstraint?
    //tag: stockviva end
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

        //tag: stockviva start
        replyViewTopConst = replyView.topAnchor.constraint(
            equalTo: bubbleView.topAnchor,
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
        photoViewTopConst = photoView.topAnchor.constraint(
            equalTo: replyView.bottomAnchor,
            constant: Padding.PhotoView.top)
        replyMsgViewBottomConst = replyMessageLabel.bottomAnchor.constraint(equalTo: replyView.bottomAnchor, constant: -Padding.ReplyMessageLabel.bottom)
        //tag: stockviva end
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.BubbleView.top).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.BubbleView.right).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: ALKPhotoCell.maxWidth*ALKPhotoCell.widthPercentage).isActive = true
        bubbleView.heightAnchor.constraint(equalToConstant: (ALKPhotoCell.maxWidth*ALKPhotoCell.heightPercentage) + Padding.BubbleView.height).isActive = true

        //tag: stockviva start
        replyViewTopConst!.isActive = true
        replyView.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.replyViewHeightIdentifier).isActive = true
        replyView.leadingAnchor.constraint(
            equalTo: bubbleView.leadingAnchor,
            constant: Padding.ReplyView.left).isActive = true
        replyView.trailingAnchor.constraint(
            equalTo: bubbleView.trailingAnchor,
            constant: -Padding.ReplyView.right).isActive = true
        
        replyIndicatorView.topAnchor.constraint(
            equalTo: replyView.topAnchor).isActive = true
        replyIndicatorView.leadingAnchor.constraint(
            equalTo: replyView.leadingAnchor).isActive = true
        replyIndicatorView.bottomAnchor.constraint(
            equalTo: replyView.bottomAnchor).isActive = true
        replyIndicatorView.widthAnchor.constraint(equalToConstant: Padding.ReplyIndicatorView.width).isActive = true
        
        replyViewInnerImgTopConst!.isActive = true
        previewImageView.trailingAnchor.constraint(
            equalTo: replyView.trailingAnchor,
            constant: -Padding.PreviewImageView.right).isActive = true
        replyViewInnerImgBottomConst!.isActive = true
        previewImageView.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.PreviewImage.height).isActive = true
        previewImageView.widthAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.PreviewImage.width).isActive = true
        
        replyNameLabel.leadingAnchor.constraint(
            equalTo:replyIndicatorView.trailingAnchor,
            constant: Padding.ReplyNameLabel.left).isActive = true
        replyViewInnerTopConst!.isActive = true
        replyNameLabel.trailingAnchor.constraint(
            equalTo: previewImageView.leadingAnchor,
            constant: -Padding.ReplyNameLabel.right).isActive = true
        replyNameLabel.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.ReplyNameLabel.height).isActive = true
        
        replyMessageTypeImageView.leadingAnchor.constraint(
            equalTo: replyIndicatorView.trailingAnchor,
            constant: Padding.ReplyMessageTypeImageView.left).isActive = true
        replyMessageTypeImageView.centerYAnchor.constraint(equalTo: replyMessageLabel.centerYAnchor).isActive = true
        replyMessageTypeImagewidthConst!.isActive = true
        replyMessageTypeImageView.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.replyMessageTypeImageViewHeight).isActive = true
        
        replyMessageLabelConst!.isActive = true
        replyMessageLabel.topAnchor.constraint(
            equalTo: replyNameLabel.bottomAnchor,
            constant: Padding.ReplyMessageLabel.top).isActive = true
        replyMessageLabel.trailingAnchor.constraint(
            equalTo: previewImageView.leadingAnchor,
            constant: -Padding.ReplyMessageLabel.right).isActive = true
        replyMessageLabel.heightAnchor.constraintLessThanOrEqualToAnchor(constant: 0,
                                                                         identifier: ConstraintIdentifier.ReplyMessageLabel.height).isActive = true
        replyMsgViewBottomConst!.isActive = true
        //tag: stockviva end
        
        photoViewTopConst!.isActive = true
        photoView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Padding.PhotoView.left).isActive = true
        photoView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Padding.PhotoView.right).isActive = true
        
        fileSizeLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -Padding.FileSizeLabel.right).isActive = true
        
        stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.StateView.top).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: Padding.StateView.right).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.StateView.bottom).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height).isActive = true
        statusViewWidthConst = stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width)
        statusViewWidthConst?.isActive = true
        
        stateErrorRemarkView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        stateErrorRemarkView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -Padding.StateErrorRemarkView.right).isActive = true
        stateErrorRemarkView.heightAnchor.constraint(equalToConstant: Padding.StateErrorRemarkView.height).isActive = true
        stateErrorRemarkView.widthAnchor.constraint(equalToConstant:Padding.StateErrorRemarkView.width).isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: Padding.TimeLabel.top).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height).isActive = true
        timeLabelRightConst = timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -Padding.TimeLabel.right)
        timeLabelRightConst?.isActive = true
    }
    
    override func update(viewModel: ALKMessageViewModel, replyMessage: ALKMessageViewModel?) {
        super.update(viewModel: viewModel, replyMessage: replyMessage)
        
//        if replyMessage != nil {
//            bubbleView.image = setBubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: false)
//            bubbleView.layer.cornerRadius = 0
//            bubbleView.backgroundColor = .clear
//        }else{
//            bubbleView.image = nil
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
//        }
        
        //update bubble style
        self.updateBubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: false)
        
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
        
        //tag: stockviva start
        //reply view
        handleReplyView(replyMessage: replyMessage)
        //tag: stockviva end
        
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
        photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//        if(ALKMessageStyle.sentBubble.style == .edge) {
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
//            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//        } else {
//            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
//        }
    }
    
    override class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat,
        replyMessage: ALKMessageViewModel?) -> CGFloat {
        
        let finalWidth:CGFloat = width*widthPercentage
        var height: CGFloat
        
        height = ceil(width*heightPercentage)
        if let message = viewModel.message, !message.isEmpty {
            height += message.rectWithConstrainedWidth(
                finalWidth,
                font: messageTextFont).height.rounded(.up) + ALKPhotoCell.Padding.CaptionLabel.top
        }
        
        //10(top padding) + height(photo content) + 32(captionLabel) + 25(statusLabel)
        var totalHeight = 10+height+32+25
        
        if ALKConfiguration.delegateConversationRequestInfo?.isHiddenMessageAdminDisclaimerLabel(viewModel: viewModel) == false {
            let _adminMsgDisclaimerHeight = super.Padding.AdminMsgDisclaimerLabel.height + super.Padding.AdminMsgDisclaimerLabel.bottom
            totalHeight += _adminMsgDisclaimerHeight
        }

        guard replyMessage != nil else { return totalHeight }
        //add reply view height
        //get width
        let _haveMsgIcon = [ALKMessageType.voice, ALKMessageType.video, ALKMessageType.photo, ALKMessageType.document].contains(replyMessage!.messageType)
        let (url, image) = ReplyMessageImage().previewFor(message: replyMessage!)
        let _havePreviewImage = url != nil || image != nil
        
        var _maxMsgWidth = finalWidth - (Padding.ReplyView.left + Padding.ReplyView.right + Padding.ReplyIndicatorView.width + Padding.ReplyMessageTypeImageView.left + Padding.ReplyMessageLabel.right + Padding.PreviewImageView.right)
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
        let _replyViewHeightInfo = ALKPhotoCell.getReplyViewHeight(Padding.ReplyView.height, defaultMsgHeight: Padding.ReplyMessageLabel.height, maxMsgHeight: Padding.ReplyMessageLabel.maxHeight, maxMsgWidth:_maxMsgWidth, replyMessageContent: _replyMsgContent)
        
        
        return totalHeight + Padding.ReplyView.top + _replyViewHeightInfo.replyViewHeight
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
    
    // MARK: - ChatMenuCell
    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        self.updateBubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: true)
    }
    
    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        self.updateBubbleViewImage(for: ALKMessageStyle.sentBubble.style, isReceiverSide: false,showHangOverImage: false)
    }
    
    //tag: stockviva start
    private func handleReplyView(replyMessage: ALKMessageViewModel?) {
        guard let replyMessage = replyMessage else {
            self.photoViewTopConst?.constant = Padding.PhotoView.top
            showReplyView(false, haveImageType: false, haveImage: false)
            return
        }
        //get setting
        let _haveMsgIcon = [ALKMessageType.voice, ALKMessageType.video, ALKMessageType.photo, ALKMessageType.document].contains(replyMessage.messageType)
        let (url, image) = ReplyMessageImage().previewFor(message: replyMessage)
        let _havePreviewImage = url != nil || image != nil
        
        self.photoViewTopConst?.constant = Padding.PhotoView.top
        if replyMessage.messageType == .text || replyMessage.messageType == .html {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = 0
        } else {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = Padding.PreviewImageView.width
        }
        showReplyView(true, haveImageType: _haveMsgIcon, haveImage: _havePreviewImage)
    }

    fileprivate func showReplyView(_ show: Bool, haveImageType:Bool, haveImage:Bool) {
        //get width
        var _maxMsgWidth = UIScreen.main.bounds.width*ALKPhotoCell.widthPercentage - (Padding.ReplyView.left + Padding.ReplyView.right + Padding.ReplyIndicatorView.width + Padding.ReplyMessageTypeImageView.left + Padding.ReplyMessageLabel.right + Padding.PreviewImageView.right)
        if haveImageType {
            _maxMsgWidth -= Padding.ReplyMessageTypeImageView.width + Padding.ReplyMessageLabel.left
        }
        if haveImage{
            _maxMsgWidth -= Padding.PreviewImageView.width
        }
        let _replyViewHeightInfo = ALKPhotoCell.getReplyViewHeight(Padding.ReplyView.height, defaultMsgHeight: Padding.ReplyMessageLabel.height, maxMsgHeight: Padding.ReplyMessageLabel.maxHeight, maxMsgWidth:_maxMsgWidth, replyMessageContent: self.replyMessageLabel.text)
            
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
    //tag: stockviva end
}
