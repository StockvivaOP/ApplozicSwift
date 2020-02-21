//
//  SVALKFriendSendGiftTableViewCell.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 19/2/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import UIKit
import Kingfisher
import Applozic

class SVALKFriendSendGiftTableViewCell: ALKChatBaseCell<ALKMessageViewModel> {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var btnAvatarImageView: UIButton!
    @IBOutlet weak var btnSendGift: UIButton!
    @IBOutlet weak var imgGiftIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageView: ALKTextView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var sendGiftButtonAction: ((ALKMessageViewModel?)->())? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.messageView.delegate = self
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height / 2.0
        self.avatarImageView.layer.masksToBounds = true
        self.btnSendGift.layer.cornerRadius = 8.0
        self.messageView.linkTextAttributes = [.foregroundColor: UIColor.ALKSVBuleColor4398FF(),
                                               .underlineStyle: NSUnderlineStyle.single.rawValue]
        self.messageView.textContainerInset = .zero
        self.messageView.textContainer.lineFragmentPadding = 0
        self.messageView.contentInset = .zero
    }
    
    func updateView(viewModel: ALKMessageViewModel){
        self.viewModel = viewModel
        //set icon
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            self.avatarImageView.image = placeHolder
        }
        //set message
        self.messageView.text = viewModel.message ?? ""
        //set gift icon
        let _giftInfo = self.viewModel?.getSendGiftMessageInfo()
        if let _giftId = _giftInfo?.giftId,
            let _giftIconUrl = ALKConfiguration.delegateSystemInfoRequestDelegate?.getGiftIconUrl(_giftId) {
            let resource = ImageResource(downloadURL: _giftIconUrl, cacheKey: _giftIconUrl.absoluteString)
            self.imgGiftIcon.kf.setImage(with: resource)
        } else {
            self.imgGiftIcon.image = nil
        }
        //set gift button
        self.btnSendGift.isHidden = true
        self.btnSendGift.setTitle(ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_send_gift") ?? "", for: .normal)
        //set name
        nameLabel.text = viewModel.displayName
        nameLabel.textColor = UIColor.ALKSVOrangeColor()
//        //set color
//        if let _messageUserId = viewModel.contactId,
//            let _nameLabelColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
//            nameLabel.textColor = _nameLabelColor
//        }
        
        //set time
        self.timeLabel.text   = viewModel.date.toConversationViewDateFormat()
    }
    
    //custom override function
    override func isMyMessage() -> Bool {
        return self.viewModel?.isMyMessage ?? false
    }
}

//MARK: button function
extension SVALKFriendSendGiftTableViewCell{
    @IBAction func sendGiftButtonTouchUpInside(_ selector: UIButton) {
        self.sendGiftButtonAction?(self.viewModel)
    }
    
    @IBAction func avatarButtonTouchUpInside(_ selector: UIButton) {
        self.avatarTapped?()
    }
}

//MARK: textview delegate
extension SVALKFriendSendGiftTableViewCell : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction != .invokeDefaultAction {
            return false
        }
        let _isOpenInApp = self.systemConfig?.enableOpenLinkInApp ?? false
        if _isOpenInApp {
            self.messageViewLinkClicked?(URL, self.viewModel)
        }
        return !_isOpenInApp
    }
}

//MARK: static function
extension SVALKFriendSendGiftTableViewCell{
    class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat, replyMessage: ALKMessageViewModel?) -> CGFloat {
        let _topHeightOfMessageView:CGFloat = 42.0
        let _bottomHeightOfMessageView:CGFloat = 30.0
        let _leftWidthOfMessageView:CGFloat = 66.0
        let _rightWidthOfMessageView:CGFloat = 124.0
        let _imageIconHeight:CGFloat = 50.0
        
        let _maxWidth = width - _leftWidthOfMessageView - _rightWidthOfMessageView
        var _messageHeight = SVALKFriendSendGiftTableViewCell.messageHeight(viewModel: viewModel, width:_maxWidth, font: UIFont.systemFont(ofSize: 16.0))
        if _messageHeight < _imageIconHeight {
            _messageHeight = _imageIconHeight
        }
        return _topHeightOfMessageView + _messageHeight + _bottomHeightOfMessageView
    }
    class func messageHeight(viewModel: ALKMessageViewModel, width: CGFloat, font: UIFont) -> CGFloat {
        let _dummyMessageView: ALKTextView = {
            let textView = ALKTextView.init(frame: .zero)
            textView.isUserInteractionEnabled = true
            textView.isSelectable = true
            textView.isEditable = false
            textView.dataDetectorTypes = .link
            textView.linkTextAttributes = [.foregroundColor: UIColor.ALKSVBuleColor4398FF(),
                                           .underlineStyle: NSUnderlineStyle.single.rawValue]
            textView.isScrollEnabled = false
            textView.delaysContentTouches = false
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.contentInset = .zero
            return textView
        }()
        _dummyMessageView.font = font
        
        /// Check if message is nil
        guard let message = viewModel.message else {
            return 0
        }
        return TextViewSizeCalculator.height(_dummyMessageView, text: message, maxWidth: width)
    }
}
