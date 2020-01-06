//
//  ALKMyDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import Foundation
import Applozic
import UIKit
import Kingfisher

class ALKMyDocumentCell: ALKDocumentCell {

    struct Padding {
        struct  StateView {
            static let right: CGFloat = 0
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
            static let height: CGFloat = 15
            static let width: CGFloat = 15
        }
        
        struct  TimeLabel {
            static let top: CGFloat = 0
            static let right: CGFloat = 1
            static let height: CGFloat = 15
        }
        struct  BubbleView {
            static let top: CGFloat = 10
            static let right: CGFloat = 7
            static let width: CGFloat = 254
        }
        
        struct  StateErrorRemarkView {
            static let right: CGFloat = 7
            static let height: CGFloat = 18
            static let width: CGFloat = 18
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
    var frameUIViewTopConst:NSLayoutConstraint?
    //tag: stockviva end
    var statusViewWidthConst:NSLayoutConstraint?
    var timeLabelRightConst:NSLayoutConstraint?
    
    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [timeLabel, stateView, stateErrorRemarkView])
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
        frameUIViewTopConst = frameUIView.topAnchor.constraint(equalTo: replyView.bottomAnchor)
        replyMsgViewBottomConst = replyMessageLabel.bottomAnchor.constraint(equalTo: replyView.bottomAnchor, constant: -Padding.ReplyMessageLabel.bottom)
        //tag: stockviva end
        
        stateView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.StateView.top).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Padding.StateView.right).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.StateView.bottom).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: Padding.StateView.height).isActive = true
        statusViewWidthConst = stateView.widthAnchor.constraint(equalToConstant: Padding.StateView.width)
        statusViewWidthConst?.isActive = true
        
        timeLabel.topAnchor.constraint(equalTo: stateView.topAnchor, constant: Padding.TimeLabel.top).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height).isActive = true
        timeLabelRightConst = timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -Padding.TimeLabel.right)
        timeLabelRightConst?.isActive = true
        
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.BubbleView.top).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.BubbleView.right).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant:Padding.BubbleView.width).isActive = true
        
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
        
        stateErrorRemarkView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        stateErrorRemarkView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -Padding.StateErrorRemarkView.right).isActive = true
        stateErrorRemarkView.heightAnchor.constraint(equalToConstant: Padding.StateErrorRemarkView.height).isActive = true
        stateErrorRemarkView.widthAnchor.constraint(equalToConstant:Padding.StateErrorRemarkView.width).isActive = true
        
        frameUIViewTopConst!.isActive = true
        frameUIView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        frameUIView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        frameUIView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
    }
    
    override func update(viewModel: ALKMessageViewModel, replyMessage: ALKMessageViewModel?) {
        super.update(viewModel: viewModel, replyMessage: replyMessage)
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
            timeLabelRightConst?.constant = -Padding.TimeLabel.right
            statusViewWidthConst?.constant = Padding.StateView.width
        }
    }

    override func setupStyle() {
        super.setupStyle()
        //timeLabel.setStyle(ALKMessageStyle.time)
    }

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.BubbleView.top + Padding.StateView.top + Padding.StateView.height + Padding.StateView.bottom
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat,replyMessage: ALKMessageViewModel?) -> CGFloat {
        let minimumHeight: CGFloat = 0
        var messageHeight : CGFloat = 0.0
        messageHeight += heightPadding()
        let totalHeight = max(messageHeight, minimumHeight)
        
        guard replyMessage != nil else { return totalHeight }
        //add reply view height
        //get width
        let _haveMsgIcon = [ALKMessageType.voice, ALKMessageType.video, ALKMessageType.photo, ALKMessageType.document].contains(replyMessage!.messageType)
        let (url, image) = ReplyMessageImage().previewFor(message: replyMessage!)
        let _havePreviewImage = url != nil || image != nil
        
        var _maxMsgWidth = Padding.BubbleView.width - (Padding.ReplyView.left + Padding.ReplyView.right + Padding.ReplyIndicatorView.width + Padding.ReplyMessageTypeImageView.left + Padding.ReplyMessageLabel.right + Padding.PreviewImageView.right)
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
        let _replyViewHeightInfo = ALKDocumentCell.getReplyViewHeight(Padding.ReplyView.height, defaultMsgHeight: Padding.ReplyMessageLabel.height, maxMsgHeight: Padding.ReplyMessageLabel.maxHeight, maxMsgWidth:_maxMsgWidth, replyMessageContent: _replyMsgContent)
        
        
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
            self.frameUIViewTopConst?.constant = 0
            showReplyView(false, haveImageType: false, haveImage: false)
            return
        }
        //get setting
        let _haveMsgIcon = [ALKMessageType.voice, ALKMessageType.video, ALKMessageType.photo, ALKMessageType.document].contains(replyMessage.messageType)
        let (url, image) = ReplyMessageImage().previewFor(message: replyMessage)
        let _havePreviewImage = url != nil || image != nil
        
        self.frameUIViewTopConst?.constant = 0
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
        let _replyViewHeightInfo = ALKDocumentCell.getReplyViewHeight(Padding.ReplyView.height, defaultMsgHeight: Padding.ReplyMessageLabel.height, maxMsgHeight: Padding.ReplyMessageLabel.maxHeight, maxMsgWidth:_maxMsgWidth, replyMessageContent: self.replyMessageLabel.text)
            
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
