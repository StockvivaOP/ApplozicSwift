//
//  ALKFriendMessageCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 12/06/19.
//

import UIKit
import Kingfisher
import Applozic

//TODO: Handle padding for reply name and reply message when preview image isn't visible.
open class ALKFriendMessageCell: ALKMessageCell {

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
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()
    
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
        
        struct BubbleView {
            static let left: CGFloat = 7.0
            static let right: CGFloat = 60.0
        }
        
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
            static let maxHeight: CGFloat = 60.0
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
        
        struct TimeLabel {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
            static let left: CGFloat = 7
            static let height: CGFloat = 13
        }
    }
    
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
    var emailViewTopConst:NSLayoutConstraint?
    
    static let bubbleViewLeftPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.receivedBubble.style == .edge else {
            return ALKMessageStyle.receivedBubble.widthPadding
        }
        return ALKMessageStyle.receivedBubble.widthPadding + 5
    }()
    
    override func setupViews() {
        super.setupViews()
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
        emailViewTopConst = emailTopView.topAnchor.constraint(
            equalTo: replyView.bottomAnchor,
            constant: Padding.MessageView.top)
        replyMsgViewBottomConst = replyMessageLabel.bottomAnchor.constraint(equalTo: replyView.bottomAnchor, constant: -Padding.ReplyMessageLabel.bottom)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)
        
        contentView.addViewsForAutolayout(views: [avatarImageView,nameLabel])
        contentView.bringSubviewToFront(messageView)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: Padding.NameLabel.top),
            nameLabel.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.NameLabel.left),
            nameLabel.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.NameLabel.right),
            nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height),
            
            avatarImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Padding.AvatarImage.top),
            avatarImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Padding.AvatarImage.left),
            avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImage.height),
            avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImage.width),
            
            bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            bubbleView.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor,
                constant: Padding.BubbleView.left),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right),
            
            replyViewTopConst!,
            replyView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyViewHeight),
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
                identifier: ConstraintIdentifier.replyPreviewImageHeight),
            previewImageView.widthAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyPreviewImageWidth),
            
            replyNameLabel.leadingAnchor.constraint(
                equalTo:replyIndicatorView.trailingAnchor,
                constant: Padding.ReplyNameLabel.left),
            replyViewInnerTopConst!,
            replyNameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyNameLabel.right),
            replyNameLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyNameHeight),
            
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
            replyMessageLabel.heightAnchor.constraintLessThanOrEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.replyMessageHeight),
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
            
            timeLabel.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.TimeLabel.left),
            timeLabel.topAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: Padding.TimeLabel.top),
            timeLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Padding.TimeLabel.bottom),
            timeLabel.heightAnchor.constraint(equalToConstant: Padding.TimeLabel.height),
            ])
    }
    
    override func setupStyle() {
        super.setupStyle()
        
        //nameLabel.setStyle(ALKMessageStyle.displayName)
        messageView.setStyle(ALKMessageStyle.receivedMessage)
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.tintColor = ALKMessageStyle.receivedBubble.color
            bubbleView.image = bubbleViewImage(for: ALKMessageStyle.receivedBubble.style, isReceiverSide: true,showHangOverImage: false)
        } else {
            bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            bubbleView.tintColor = ALKMessageStyle.receivedBubble.color
            bubbleView.backgroundColor = ALKMessageStyle.receivedBubble.color
        }
    }

    func update(viewModel: ALKMessageViewModel, replyMessage: ALKMessageViewModel?) {
        super.update(viewModel: viewModel, style: ALKMessageStyle.receivedMessage, replyMessage: replyMessage)
        handleReplyView(replyMessage: replyMessage)
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            self.avatarImageView.image = placeHolder
        }
        
        nameLabel.text = viewModel.displayName
        nameLabel.textColor = UIColor.ALKSVOrangeColor()
        //set color
        if let _messageUserId = viewModel.contactId,
            let _nameLabelColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            nameLabel.textColor = _nameLabelColor
        }
    }

    class func rowHeigh(viewModel: ALKMessageViewModel,
                        width: CGFloat,
                        replyMessage: ALKMessageViewModel?) -> CGFloat {
        let minimumHeight = Padding.AvatarImage.top + Padding.AvatarImage.height + 5
        
        /// Calculating available width for messageView
        let leftSpacing = Padding.AvatarImage.left + Padding.AvatarImage.width + Padding.BubbleView.left + bubbleViewLeftPadding
        let rightSpacing = Padding.BubbleView.right + ALKMessageStyle.receivedBubble.widthPadding
        let messageWidth = width - (leftSpacing + rightSpacing)
        
        /// Calculating messageHeight
        let messageHeight = super.messageHeight(viewModel: viewModel, width: messageWidth, font: ALKMessageStyle.receivedMessage.font)
        var heightPadding = Padding.AvatarImage.top + Padding.NameLabel.top + Padding.NameLabel.height + Padding.MessageView.bottom + Padding.TimeLabel.top + Padding.TimeLabel.height + Padding.TimeLabel.bottom
        if viewModel.isReplyMessage {
            heightPadding += Padding.MessageView.top + Padding.ReplyView.top
        }
        
        let totalHeight = max((messageHeight + heightPadding), minimumHeight)
        
        guard replyMessage != nil else { return totalHeight }
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
    
    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
    
    // MARK: - ChatMenuCell
    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if(ALKMessageStyle.receivedBubble.style == .edge){
            self.bubbleView.image = bubbleViewImage(for: ALKMessageStyle.receivedBubble.style,isReceiverSide: true,showHangOverImage: true)
        }
    }
    
    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if(ALKMessageStyle.receivedBubble.style == .edge){
            self.bubbleView.image =  bubbleViewImage(for: ALKMessageStyle.receivedBubble.style,isReceiverSide: true,showHangOverImage: false)
        }
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
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.replyPreviewImageWidth)?.constant = 0
        } else {
            previewImageView.constraint(withIdentifier: ConstraintIdentifier.replyPreviewImageWidth)?.constant = Padding.PreviewImageView.width
        }
        
        showReplyView(true, haveImageType: _haveMsgIcon, haveImage: _havePreviewImage)
    }

    private func showReplyView(_ show: Bool, haveImageType:Bool, haveImage:Bool) {
        //get width
        let leftSpacing = Padding.AvatarImage.left + Padding.AvatarImage.width + Padding.BubbleView.left + ALKFriendMessageCell.bubbleViewLeftPadding
        let rightSpacing = Padding.BubbleView.right + ALKMessageStyle.receivedBubble.widthPadding
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
}
