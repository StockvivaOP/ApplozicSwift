//
//  ALKFriendDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import Foundation
import Applozic
import UIKit
import Kingfisher
import Applozic

class ALKFriendDocumentCell: ALKDocumentCell {

    struct Padding {

        struct NameLabel {
            static let top: CGFloat = 7.0
            static let left: CGFloat = 7.0
            static let right: CGFloat = 11.0
            static let height: CGFloat = 20.0
        }
        
        struct AvatarImage {
            static let top: CGFloat = 10.0
            static let left: CGFloat = 7.0
            static let width: CGFloat = 45.0
            static let height: CGFloat = 45.0
        }
        
        struct ButtonSendGift {
            static let top: CGFloat = 2.0
            static let width: CGFloat = 34.0
            static let height: CGFloat = 16.0
        }
        
        struct TimeLabel {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
            static let left: CGFloat = 7
            static let height: CGFloat = 13
        }
        
        struct BubbleView {
            static let left: CGFloat = 7.0
            static let width: CGFloat = 254
        }

        struct FrameUIView {
            static let top: CGFloat = 0.0
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

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 22.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()
    
    var btnSendGift: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = true
        button.setTextColor(color: UIColor.white, forState: .normal)
        button.setFont(font: UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.medium))
        button.setBackgroundColor(UIColor.ALKSVMainColorPurple())
        button.layer.cornerRadius = 8.0
        return button
    }()
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()
    
    //tag: stockviva start
    var sendGiftButtonAction: ((ALKMessageViewModel?)->())? = nil
    struct ConstraintIdentifier {
        static let replyViewHeight = "ReplyViewHeight"
        static let replyNameHeight = "ReplyNameHeight"
        static let replyMessageHeight = "ReplyMessageHeight"
        static let replyMessageTypeImageViewHeight = "replyMessageTypeImageViewHeight"
        static let replyPreviewImageHeight = "ReplyPreviewImageHeight"
        static let replyPreviewImageWidth = "ReplyPreviewImageWidth"
    }
    var replyViewTopConst:NSLayoutConstraint?
    var replyViewInnerTopConst:NSLayoutConstraint?
    var replyViewInnerImgTopConst:NSLayoutConstraint?
    var replyViewInnerImgBottomConst:NSLayoutConstraint?
    var replyMsgViewBottomConst:NSLayoutConstraint?
    var frameUIViewTopConst:NSLayoutConstraint?
    //tag: stockviva end

    override func setupViews() {
        super.setupViews()
        self.btnSendGift.addTarget(self, action: #selector(self.sendGiftButtonTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
        
        //tag: stockviva start
        replyViewTopConst = replyView.topAnchor.constraint(
            equalTo: nameLabel.bottomAnchor,
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
        frameUIViewTopConst = frameUIView.topAnchor.constraint(
            equalTo: replyView.bottomAnchor,
            constant: Padding.FrameUIView.top)
        replyMsgViewBottomConst = replyMessageLabel.bottomAnchor.constraint(equalTo: replyView.bottomAnchor, constant: -Padding.ReplyMessageLabel.bottom)
        //tag: stockviva end

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView,nameLabel,btnSendGift,timeLabel])
        
        nameLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: Padding.NameLabel.top).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Padding.NameLabel.left).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Padding.NameLabel.right).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height).isActive = true
        
        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.AvatarImage.top).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.AvatarImage.left).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImage.height).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImage.width).isActive = true

        btnSendGift.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: Padding.ButtonSendGift.top).isActive = true
        btnSendGift.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor).isActive = true
        btnSendGift.heightAnchor.constraint(equalToConstant: Padding.ButtonSendGift.height).isActive = true
        btnSendGift.widthAnchor.constraint(equalToConstant: Padding.ButtonSendGift.width).isActive = true
        
        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Padding.TimeLabel.left).isActive = true
        timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.TimeLabel.top).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.TimeLabel.bottom).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height).isActive = true
        
        bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.BubbleView.left).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant:Padding.BubbleView.width).isActive = true
        
        frameUIViewTopConst!.isActive = true
        frameUIView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        frameUIView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        frameUIView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        
        //tag: stockviva start
        replyViewTopConst!.isActive = true
        replyView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyViewHeight).isActive = true
        replyView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Padding.ReplyView.left).isActive = true
        replyView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Padding.ReplyView.right).isActive = true
        
        replyIndicatorView.topAnchor.constraint(equalTo: replyView.topAnchor).isActive = true
        replyIndicatorView.leadingAnchor.constraint(equalTo: replyView.leadingAnchor).isActive = true
        replyIndicatorView.bottomAnchor.constraint(equalTo: replyView.bottomAnchor).isActive = true
        replyIndicatorView.widthAnchor.constraint(equalToConstant: Padding.ReplyIndicatorView.width).isActive = true
        
        replyViewInnerImgTopConst!.isActive = true
        previewImageView.trailingAnchor.constraint(equalTo: replyView.trailingAnchor, constant: -Padding.PreviewImageView.right).isActive = true
        replyViewInnerImgBottomConst!.isActive = true
        previewImageView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyPreviewImageHeight).isActive = true
        previewImageView.widthAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyPreviewImageWidth).isActive = true
        
        replyNameLabel.leadingAnchor.constraint(equalTo:replyIndicatorView.trailingAnchor, constant: Padding.ReplyNameLabel.left).isActive = true
        replyViewInnerTopConst!.isActive = true
        replyNameLabel.trailingAnchor.constraint(equalTo: previewImageView.leadingAnchor, constant: -Padding.ReplyNameLabel.right).isActive = true
        replyNameLabel.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyNameHeight).isActive = true
        
        replyMessageTypeImageView.leadingAnchor.constraint(equalTo: replyIndicatorView.trailingAnchor, constant: Padding.ReplyMessageTypeImageView.left).isActive = true
        replyMessageTypeImageView.centerYAnchor.constraint(equalTo: replyMessageLabel.centerYAnchor).isActive = true
        replyMessageTypeImagewidthConst!.isActive = true
        replyMessageTypeImageView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyMessageTypeImageViewHeight).isActive = true
        
        replyMessageLabelConst!.isActive = true
        replyMessageLabel.topAnchor.constraint(equalTo: replyNameLabel.bottomAnchor, constant: Padding.ReplyMessageLabel.top).isActive = true
        replyMessageLabel.trailingAnchor.constraint(equalTo: previewImageView.leadingAnchor, constant: -Padding.ReplyMessageLabel.right).isActive = true
        replyMessageLabel.heightAnchor.constraintLessThanOrEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyMessageHeight).isActive = true
        replyMsgViewBottomConst!.isActive = true
        //tag: stockviva end
    }
    
    override func update(viewModel: ALKMessageViewModel, replyMessage: ALKMessageViewModel?) {
        super.update(viewModel: viewModel, replyMessage: replyMessage)
        self.updateBubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: false)
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            self.avatarImageView.image = placeHolder
        }
        self.btnSendGift.setTitle(ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_send_gift") ?? "", for: .normal)
        
        nameLabel.text = viewModel.displayName
        nameLabel.textColor = UIColor.ALKSVOrangeColor()
        //set color
        if let _messageUserId = viewModel.contactId,
            let _nameLabelColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            nameLabel.textColor = _nameLabelColor
        }
        //tag: stockviva start
        //reply view status
        handleReplyView(replyMessage: replyMessage)
        //tag: stockviva end
    }

    override func setupStyle() {
        super.setupStyle()
        //timeLabel.setStyle(ALKMessageStyle.time)
        //nameLabel.setStyle(ALKMessageStyle.displayName)
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat,replyMessage: ALKMessageViewModel?) -> CGFloat {
        let minimumHeight: CGFloat = 60 // 55 is avatar image... + padding
        let messageHeight : CGFloat = self.heightPadding()
        var totalHeight = max(messageHeight, minimumHeight)
        
        let _isDeletedMsg = viewModel.getDeletedMessageInfo().isDeleteMessage
        if ALKConfiguration.delegateConversationRequestInfo?.isHiddenMessageAdminDisclaimerLabel(viewModel: viewModel) == false && _isDeletedMsg == false {
            let _adminMsgDisclaimerHeight = CommonPadding.AdminMsgDisclaimerLabel.height + CommonPadding.AdminMsgDisclaimerLabel.bottom
            totalHeight += _adminMsgDisclaimerHeight
        }
        
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

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.AvatarImage.top + Padding.NameLabel.top + Padding.NameLabel.height + Padding.FrameUIView.top + Padding.TimeLabel.top + Padding.TimeLabel.height + Padding.TimeLabel.bottom
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
    
    @objc private func sendGiftButtonTouchUpInside(_ selector: UIButton) {
        self.sendGiftButtonAction?(self.viewModel)
    }
    
    // MARK: - ChatMenuCell
    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        self.updateBubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: true)
    }
    
    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        self.updateBubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: false)
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
        
        self.frameUIViewTopConst?.constant = Padding.FrameUIView.top
        if replyMessage.messageType == .text || replyMessage.messageType == .html {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.replyPreviewImageWidth)?.constant = 0
        } else {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.replyPreviewImageWidth)?.constant = Padding.PreviewImageView.width
        }
        
        showReplyView(true, haveImageType: _haveMsgIcon, haveImage: _havePreviewImage)
    }

    private func showReplyView(_ show: Bool, haveImageType:Bool, haveImage:Bool) {
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
            .constraint(withIdentifier: ConstraintIdentifier.replyViewHeight)?
            .constant = show ? _replyViewHeightInfo.replyViewHeight : 0
        replyNameLabel
            .constraint(withIdentifier: ConstraintIdentifier.replyNameHeight)?
            .constant = show ? Padding.ReplyNameLabel.height : 0
        replyMessageLabel
            .constraint(withIdentifier: ConstraintIdentifier.replyMessageHeight)?
            .constant = show ? _replyViewHeightInfo.replyMsgViewHeight : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.replyPreviewImageHeight)?
            .constant = haveImage ? Padding.PreviewImageView.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.replyPreviewImageWidth)?
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
