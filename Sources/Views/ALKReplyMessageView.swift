//
//  ALKReplyMessageView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 07/02/18.
//

import UIKit
import Applozic

/* Reply message view to be used in the
 bottom (above chat bar) when replying
 to a message */

open class ALKReplyMessageView: UIView, Localizable {

    var configuration: ALKConfiguration!
    var delegateCellRequestInfo:ConversationCellRequestInfoDelegate?

    open var nameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.text = "Name"
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        return label
    }()

    open var messageLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.text = "The message"
        label.numberOfLines = 3
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVGreyColor102()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    open var closeButton: UIButton = {
        let button = UIButton(frame: CGRect.zero)
        let closeImage = UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(closeImage, for: .normal)
        return button
    }()

    open var previewImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var indicatorView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ALKSVOrangeColor()
        return view
    }()
    
    let messageTypeImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    open var lineView: UIView = {
        let view = UIView()
        let layer = view.layer
        view.backgroundColor = UIColor.ALKSVGreyColor207()
        return view
    }()
    
    lazy open var selfNameText: String = {
        let text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_you") ?? localizedString(forKey: "You", withDefaultValue: SystemMessage.LabelName.You, fileName: configuration.localizedStringFileName)
        return text
    }()

    public var closeButtonTapped: ((Bool)->Void)?

    private var message: ALKMessageViewModel?

    private enum Padding {

        enum NameLabel {
            static let height: CGFloat = 20.0
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let top: CGFloat = 5.0
        }

        enum MessageLabel {
            static let height: CGFloat = 60.0
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let top: CGFloat = 0.0
            static let bottom: CGFloat = 5.0
        }

        enum CloseButton {
            static let height: CGFloat = 25.0
            static let width: CGFloat = 25.0
            static let right: CGFloat = 15.0
            static let top: CGFloat = 5.0
        }

        enum PreviewImageView {
            static let height: CGFloat = 40.0
            static let width: CGFloat = 48.0
            static let right: CGFloat = 6.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5.0
        }

        struct IndicatorView {
            static let left: CGFloat = 7.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5.0
            static let width: CGFloat = 4.0
        }
        
        struct MessageTypeImageView {
            static let left: CGFloat = 5.0
            static let width: CGFloat = 20.0
            static let height: CGFloat = 20.0
        }
        
        struct LineView {
            static let left: CGFloat = 0.0
            static let right: CGFloat = 0.0
            static let top: CGFloat = 0.0
            static let height: CGFloat = 1.0
        }
    }

    var messageTypeImagewidthConst:NSLayoutConstraint?
    var messageLabelLeadingConst:NSLayoutConstraint?
    
    init(frame: CGRect, configuration: ALKConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        setUpViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(message: ALKMessageViewModel) {
        self.message = message
        nameLabel.text = message.isMyMessage ?
            selfNameText:message.displayName
        nameLabel.textColor = UIColor.ALKSVOrangeColor()
        messageLabel.text = getMessageText()

        let (url, image) = ReplyMessageImage().previewFor(message: message)
        if let url = url {
            setImageFrom(url: url, to: previewImageView)
        } else {
            previewImageView.image = image
        }
        //update reply icon
        if message.messageType == ALKMessageType.voice  {
            messageTypeImageView.image = UIImage(named: "sv_icon_chatroom_audio_grey", in: Bundle.applozic, compatibleWith: nil)
            messageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_audio") ?? messageLabel.text
        }else if message.messageType == ALKMessageType.video {
            messageTypeImageView.image = UIImage(named: "sv_icon_chatroom_video_grey", in: Bundle.applozic, compatibleWith: nil)
            messageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_video") ?? messageLabel.text
        }else if message.messageType == ALKMessageType.photo {
            messageTypeImageView.image = UIImage(named: "sv_icon_chatroom_photo_grey", in: Bundle.applozic, compatibleWith: nil)
            messageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? messageLabel.text
        }else if message.messageType == ALKMessageType.document {
            messageTypeImageView.image = UIImage(named: "sv_icon_chatroom_file_grey", in: Bundle.applozic, compatibleWith: nil)
            messageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_document") ?? messageLabel.text
        }else{
            messageTypeImageView.image = nil
        }
        
        if messageTypeImageView.image == nil {
            messageTypeImagewidthConst?.constant = 0
            messageLabelLeadingConst?.constant = 0
        }else{
            messageTypeImagewidthConst?.constant = 20
            messageLabelLeadingConst?.constant = 5
        }
        indicatorView.backgroundColor = UIColor.ALKSVOrangeColor()
        
        //set color
        var _contactID:String? = nil
        if message.isMyMessage {
            _contactID = self.delegateCellRequestInfo?.getSelfUserHashId()
        }else{
            _contactID = message.contactId
        }
        
        if let _messageUserId = _contactID,
            let _userColor = self.configuration.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            nameLabel.textColor = _userColor
            indicatorView.backgroundColor = _userColor
        }
    }

    // MARK: - Internal methods

    private func setUpViews() {
        setUpConstraints()
        closeButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
    }

    private func setUpConstraints() {
        self.addViewsForAutolayout(views: [lineView, indicatorView, nameLabel, messageTypeImageView, messageLabel, closeButton, previewImageView])
        
        messageTypeImagewidthConst = messageTypeImageView.widthAnchor.constraint(equalToConstant: Padding.MessageTypeImageView.width)
        messageLabelLeadingConst = messageLabel.leadingAnchor.constraint(equalTo: messageTypeImageView.trailingAnchor, constant: Padding.MessageLabel.left)
        
        let view = self
        
        lineView.topAnchor.constraint(equalTo: view.topAnchor, constant: Padding.LineView.top).isActive = true
        lineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.LineView.left).isActive = true
        lineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Padding.LineView.right).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: Padding.LineView.height).isActive = true
        
        indicatorView.topAnchor.constraint(equalTo: view.topAnchor, constant: Padding.IndicatorView.top).isActive = true
        indicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.IndicatorView.left).isActive = true
        indicatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Padding.IndicatorView.bottom).isActive = true
        indicatorView.widthAnchor.constraint(equalToConstant: Padding.IndicatorView.width).isActive = true
        
        nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: Padding.NameLabel.left).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: previewImageView.leadingAnchor, constant: -Padding.NameLabel.right).isActive = true
        nameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Padding.NameLabel.top).isActive = true

        messageTypeImageView.leadingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: Padding.MessageTypeImageView.left).isActive = true
        messageTypeImageView.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor).isActive = true
        messageTypeImagewidthConst!.isActive = true
        messageTypeImageView.heightAnchor.constraint(equalToConstant: Padding.MessageTypeImageView.height).isActive = true
        
        messageLabel.heightAnchor.constraint(lessThanOrEqualToConstant: Padding.MessageLabel.height)
        messageLabelLeadingConst!.isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: previewImageView.leadingAnchor, constant: -Padding.MessageLabel.right).isActive = true
        messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.MessageLabel.top).isActive = true
        messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Padding.MessageLabel.bottom).isActive = true

        closeButton.heightAnchor.constraint(equalToConstant: Padding.CloseButton.height).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: Padding.CloseButton.width).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Padding.CloseButton.right).isActive = true
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Padding.CloseButton.top).isActive = true

        previewImageView.heightAnchor.constraint(equalToConstant: Padding.PreviewImageView.height).isActive = true
        previewImageView.widthAnchor.constraint(equalToConstant: Padding.PreviewImageView.width).isActive = true
        previewImageView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -Padding.PreviewImageView.right).isActive = true
        previewImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: Padding.PreviewImageView.top).isActive = true
        previewImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Padding.PreviewImageView.bottom).isActive = true

    }

    func getViewHeight() -> CGFloat{
        var _result:CGFloat = Padding.NameLabel.top + Padding.NameLabel.height + Padding.MessageLabel.top + Padding.MessageLabel.bottom
        _result += messageLabel.sizeThatFits(CGSize(width: messageLabel.frame.size.width, height: 60) ).height
        return _result
    }
    
    @objc private func closeButtonTapped(_ sender: UIButton) {
        closeButtonTapped?(true)
    }

    private func getMessageText() -> String? {
        guard let message = message else {return nil}
        switch message.messageType {
        case .text, .html:
            return message.message
        default:
            return message.messageType.rawValue
        }
    }

    private func setImageFrom(url: URL?, to imageView: UIImageView) {
        imageView.kf.setImage(with: url)
    }

}
