//
//  ALKMessageBaseCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 12/06/19.
//

import UIKit
import Kingfisher
import Applozic


class ALKImageView: UIImageView {

    // To highlight when long pressed
    override open var canBecomeFirstResponder: Bool {
        return true
    }
}

open class ALKMessageCell: ALKChatBaseCell<ALKMessageViewModel>, ALKCopyMenuItemProtocol, ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol {

    /// Dummy view required to calculate height for normal text.
    fileprivate static var dummyMessageView: ALKTextView = {
        let textView = ALKTextView.init(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        return textView
    }()

    /// Dummy view required to calculate height for attributed text.
    /// Required because we are using static textview which doesn't clear attributes
    /// once attributed string is used.
    /// See this question https://stackoverflow.com/q/21731207/6671572
    fileprivate static var dummyAttributedMessageView: ALKTextView = {
        let textView = ALKTextView.init(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        return textView
    }()

    fileprivate static var attributedStringCache = NSCache<NSString, NSAttributedString>()

    var messageView: ALKTextView = {
        let textView = ALKTextView.init(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        textView.textColor = UIColor.ALKSVPrimaryDarkGrey()
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        lb.textColor = UIColor.ALKSVGreyColor153()
        lb.isOpaque = true
        return lb
    }()

    var bubbleView: ALKImageView = {
        let bv = ALKImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = true
        bv.isOpaque = true
        return bv
    }()

    var replyView: ALKImageView = {
        let view = ALKImageView()
        view.backgroundColor = UIColor.clear
        view.tintColor = UIColor.ALKSVGreyColor250()
        view.isUserInteractionEnabled = true
        return view
    }()

    var replyIndicatorView: ALKImageView = {
        let view = ALKImageView()
        view.clipsToBounds = true
        view.isOpaque = true
        view.backgroundColor = UIColor.ALKSVOrangeColor()
        view.tintColor = UIColor.ALKSVOrangeColor()
        view.contentMode = .scaleToFill
        return view
    }()
    
    var replyNameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVOrangeColor()
        label.numberOfLines = 1
        return label
    }()
    
    let replyMessageTypeImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var replyMessageLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVGreyColor102()
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let previewImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let emailTopView = ALKEmailTopView(frame: .zero)

    lazy var emailTopHeight = emailTopView.heightAnchor.constraint(equalToConstant: 0)

    fileprivate static let paragraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle.init()
        style.lineBreakMode = .byWordWrapping
        style.headIndent = 0
        style.tailIndent = 0
        style.firstLineHeadIndent = 0
        style.minimumLineHeight = 17
        style.maximumLineHeight = 17
        return style
    }()

    lazy var selfNameText: String = {
        let text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_you") ?? localizedString(forKey: "You", withDefaultValue: SystemMessage.LabelName.You, fileName: localizedStringFileName)
        return text
    }()

    var replyViewAction: (()->())? = nil
    
    var replyMessageTypeImagewidthConst:NSLayoutConstraint?
    var replyMessageLabelConst:NSLayoutConstraint?

    func update(viewModel: ALKMessageViewModel, style: Style, replyMessage: ALKMessageViewModel?) {
        self.viewModel = viewModel

        if let replyMessage = replyMessage {
            replyNameLabel.text = replyMessage.isMyMessage ?
                selfNameText : replyMessage.displayName
            replyMessageLabel.text =
                getMessageTextFrom(viewModel: replyMessage)
            //update reply icon
            if replyMessage.messageType == ALKMessageType.voice  {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_audio_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_audio") ?? replyMessageLabel.text
            }else if replyMessage.messageType == ALKMessageType.video {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_video_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_video") ?? replyMessageLabel.text
            }else if replyMessage.messageType == ALKMessageType.photo {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_photo_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? replyMessageLabel.text
            }else if replyMessage.messageType == ALKMessageType.document {
                replyMessageTypeImageView.image = UIImage(named: "sv_icon_chatroom_file_grey", in: Bundle.applozic, compatibleWith: nil)
                replyMessageLabel.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_document") ?? replyMessageLabel.text
            }else{
                replyMessageTypeImageView.image = nil
            }
            let (url, image) = ReplyMessageImage().previewFor(message: replyMessage)
            if let url = url {
                setImageFrom(url: url, to: previewImageView)
            } else {
                previewImageView.image = image
            }
        } else {
            replyNameLabel.text = ""
            replyMessageLabel.text = ""
            replyMessageTypeImageView.image = nil
            previewImageView.image = nil
        }
        
        if replyMessageTypeImageView.image == nil {
            replyMessageTypeImagewidthConst?.constant = 0
            replyMessageLabelConst?.constant = 0
        }else{
            replyMessageTypeImagewidthConst?.constant = 20
            replyMessageLabelConst?.constant = 5
        }
        if viewModel.isMyMessage {
            replyNameLabel.textColor = UIColor.ALKSVOrangeColor()
            replyView.image = setReplyViewImage(isReceiverSide: false)
            replyIndicatorView.image = UIImage.init(named: "sv_button_chatroom_reply_orange", in: Bundle.applozic, compatibleWith: nil)
            replyIndicatorView.backgroundColor = UIColor.clear
            replyIndicatorView.tintColor = UIColor.ALKSVOrangeColor()
            //set color
            if let _messageUserId = replyMessage?.receiverId,
                let _userColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
                replyNameLabel.textColor = _userColor
                replyIndicatorView.tintColor = _userColor
            }
        }else{
            replyView.image = setReplyViewImage(isReceiverSide: true)
            replyIndicatorView.backgroundColor = UIColor.ALKSVOrangeColor()
            replyIndicatorView.tintColor = UIColor.ALKSVOrangeColor()
            replyIndicatorView.image = nil
            //set color
            if let _messageUserId = replyMessage?.receiverId,
                let _userColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
                replyNameLabel.textColor = _userColor
                replyIndicatorView.backgroundColor = _userColor
                replyIndicatorView.tintColor = _userColor
            }
        }

        self.timeLabel.text   = viewModel.time
        resetTextView(style)
        guard let message = viewModel.message else { return }

        switch viewModel.messageType {
        case .text:
            emailTopHeight.constant = 0
            messageView.text = message
            return
        case .html:
            emailTopHeight.constant = 0
            emailTopView.show(false)
        case .email:
            emailTopHeight.constant = ALKEmailTopView.height
            emailTopView.show(true)
        default:
            print("😱😱😱Shouldn't come here.😱😱😱")
            return
        }
        /// Comes here for html and email
        DispatchQueue.global().async {
            let attributedText = ALKMessageCell.attributedStringFrom(message, for: viewModel.identifier)
            DispatchQueue.main.async {
                self.messageView.attributedText = attributedText
            }
        }
    }

    override func setupViews() {
        super.setupViews()
        messageView.delegate = self
        
        contentView.addViewsForAutolayout(views:
            [messageView,
             bubbleView,
             emailTopView,
             replyView,
             replyIndicatorView,
             replyNameLabel,
             replyMessageTypeImageView,
             replyMessageLabel,
             previewImageView,
             timeLabel])
        
        contentView.bringSubviewToFront(messageView)
        contentView.bringSubviewToFront(emailTopView)

        bubbleView.addGestureRecognizer(longPressGesture)
        let replyTapGesture = UITapGestureRecognizer(target: self, action: #selector(replyViewTapped))
        replyView.addGestureRecognizer(replyTapGesture)
    }

    override func setupStyle() {
        super.setupStyle()
        //timeLabel.setStyle(ALKMessageStyle.time)
    }
    
    override func isMyMessage() -> Bool {
        return self.viewModel?.isMyMessage ?? false
    }
    
    class func messageHeight(viewModel: ALKMessageViewModel,
                             width: CGFloat,
                             font: UIFont) -> CGFloat {
        dummyMessageView.font = font

        /// Check if message is nil
        guard let message = viewModel.message else {
            return 0
        }

        switch viewModel.messageType {
        case .text:
            return TextViewSizeCalculator.height(dummyMessageView, text: message, maxWidth: width)
        case .html:
            guard let attributedText = attributedStringFrom(message, for: viewModel.identifier) else {
                return 0
            }
            dummyAttributedMessageView.font = font
            let height = TextViewSizeCalculator.height(
                dummyAttributedMessageView,
                attributedText: attributedText,
                maxWidth: width)
            return height
        case .email:
                guard let attributedText = attributedStringFrom(message, for: viewModel.identifier) else {
                    return ALKEmailTopView.height
                }
                dummyAttributedMessageView.font = font
                let height = ALKEmailTopView.height +
                    TextViewSizeCalculator.height(
                        dummyAttributedMessageView,
                        attributedText: attributedText,
                        maxWidth: width)
                return height
        default:
            print("😱😱😱Shouldn't come here.😱😱😱")
            return 0
        }
    }

    func menuCopy(_ sender: Any) {
        UIPasteboard.general.string = self.viewModel?.message ?? ""
    }
    
    func menuAppeal(_ sender: Any) {
        menuAction?(.appeal(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.contactId, messageID: self.viewModel?.identifier, message: self.viewModel?.message))
    }
    
    func menuPinMsg(_ sender: Any) {
        menuAction?(.pinMsg(chatGroupHashID: self.clientChannelKey, userHashID: self.viewModel?.contactId, viewModel: self.viewModel, indexPath:self.indexPath))
    }

    func menuReply(_ sender: Any) {
        menuAction?(.reply)
    }

    @objc func replyViewTapped() {
        replyViewAction?()
    }

    func bubbleViewImage(for style: ALKMessageStyle.BubbleStyle, isReceiverSide: Bool = false,showHangOverImage:Bool) -> UIImage? {

        var imageTitle = showHangOverImage ? "chat_bubble_red_hover":"chat_bubble_red"
        // We can rotate the above image but loading the required
        // image would be faster and we already have both the images.
        if isReceiverSide {imageTitle = showHangOverImage ? "chat_bubble_grey_hover":"chat_bubble_grey"}

        guard let bubbleImage = UIImage.init(named: imageTitle, in: Bundle.applozic, compatibleWith: nil)
            else {return nil}

        // This API is from the Kingfisher so instead of directly using
        // imageFlippedForRightToLeftLayoutDirection() we are using this as it handles
        // platform availability and future updates for us.
        let modifier = FlipsForRightToLeftLayoutDirectionImageModifier()
        return modifier.modify(bubbleImage)

    }

    // MARK: - Private helper methods

    private class func attributedStringFrom(_ text: String, for id: String) -> NSAttributedString? {
        if let attributedString = attributedStringCache.object(forKey: id as NSString) {
            return attributedString
        }
        guard let htmlText = text.data(using: .utf8, allowLossyConversion: false) else {
            print("🤯🤯🤯Could not create UTF8 formatted data from \(text)")
            return nil
        }
        do {
            let attributedString = try NSAttributedString(
                data: htmlText,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
            self.attributedStringCache.setObject(attributedString, forKey: id as NSString)
            return attributedString
        } catch {
            print("😢😢😢 Error \(error) while creating attributed string")
            return nil
        }
    }

    private func getMessageTextFrom(viewModel: ALKMessageViewModel) -> String? {
        switch viewModel.messageType {
        case .text, .html:
            return viewModel.message
        default:
            return viewModel.messageType.rawValue
        }
    }

    private func removeDefaultLongPressGestureFrom(_ textView: UITextView) {
        if let gestures = textView.gestureRecognizers {
            for ges in gestures {
                if ges.isKind(of: UILongPressGestureRecognizer.self) {
                    ges.isEnabled = false

                }
                else if ges.isKind(of: UITapGestureRecognizer.self) {
                    (ges as? UITapGestureRecognizer)?.numberOfTapsRequired = 1
                }
            }
        }
    }

    private func setImageFrom(url: URL?, to imageView: UIImageView) {
        guard let url = url else { return }
        let provider = LocalFileImageDataProvider(fileURL: url)
        imageView.kf.setImage(with: provider)
    }

    /// This hack is required cuz textView won't clear its attributes.
    /// See this: https://stackoverflow.com/q/21731207/6671572
    private func resetTextView(_ style: Style) {
        messageView.attributedText = nil
        messageView.text = nil
        messageView.typingAttributes = [:]
        messageView.setStyle(style)
    }
    
    static func getReplyViewHeight(_ defaultReplyViewHeight:CGFloat = 0, defaultMsgHeight:CGFloat = 0, maxMsgHeight:CGFloat, maxMsgWidth:CGFloat, replyMessageContent:String?) -> (replyViewHeight:CGFloat, replyMsgViewHeight:CGFloat, offsetOfMsgIncreaseHeight:CGFloat){
        
        let _tempLabel:UILabel = UILabel(frame: CGRect.zero)
        _tempLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        _tempLabel.textColor = UIColor.ALKSVGreyColor102()
        _tempLabel.numberOfLines = 3
        _tempLabel.lineBreakMode = .byTruncatingTail
        _tempLabel.text = replyMessageContent
        
        var _resultMsgHeight:CGFloat = _tempLabel.sizeThatFits(CGSize(width: maxMsgWidth, height: maxMsgHeight) ).height
        if _resultMsgHeight < defaultMsgHeight {
            _resultMsgHeight = defaultMsgHeight
        }
        let _offsetOfMsgIncreaseHeight = (_resultMsgHeight - defaultMsgHeight)
        var _replyViewViewHeight = defaultReplyViewHeight + _offsetOfMsgIncreaseHeight
        if _replyViewViewHeight < defaultReplyViewHeight {
            _replyViewViewHeight = defaultReplyViewHeight
        }
        return (replyViewHeight:_replyViewViewHeight, replyMsgViewHeight:_resultMsgHeight, offsetOfMsgIncreaseHeight:_offsetOfMsgIncreaseHeight)
    }
}

extension ALKMessageCell : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let _isOpenInApp = self.systemConfig?.enableOpenLinkInApp ?? false
        if _isOpenInApp {
            self.messageViewLinkClicked?(URL)
        }
        return !_isOpenInApp
    }
}
