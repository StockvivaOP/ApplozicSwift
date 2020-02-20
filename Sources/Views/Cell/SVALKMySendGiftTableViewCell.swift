//
//  SVALKMySendGiftTableViewCell.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 19/2/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import UIKit
import Kingfisher
import Applozic

class SVALKMySendGiftTableViewCell: ALKChatBaseCell<ALKMessageViewModel> {
    
    @IBOutlet weak var imgGiftIcon: UIImageView!
    @IBOutlet weak var messageView: ALKTextView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stateView: UIImageView!
    @IBOutlet weak var stateErrorRemarkView: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.messageView.delegate = self
        self.messageView.linkTextAttributes = [.foregroundColor: UIColor.ALKSVBuleColor4398FF(),
                                               .underlineStyle: NSUnderlineStyle.single.rawValue]
        self.messageView.textContainerInset = .zero
        self.messageView.textContainer.lineFragmentPadding = 0
        self.messageView.contentInset = .zero
    }
    
    func updateView(viewModel: ALKMessageViewModel){
        self.viewModel = viewModel
        //set gift icon
        let _giftInfo = self.viewModel?.getSendGiftMessageInfo()
        if let _giftId = _giftInfo?.giftId,
            let _giftIconUrl = ALKConfiguration.delegateSystemInfoRequestDelegate?.getGiftIconUrl(_giftId) {
            let resource = ImageResource(downloadURL: _giftIconUrl, cacheKey: _giftIconUrl.absoluteString)
            self.imgGiftIcon.kf.setImage(with: resource)
        } else {
            self.imgGiftIcon.image = nil
        }
        //set message
        self.messageView.text = viewModel.message ?? ""
        //set time
        self.timeLabel.text   = viewModel.date.toConversationViewDateFormat()
        //set message status
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
        //set up state view
        stateView.isHidden = self.systemConfig?.hideConversationBubbleState ?? false
        if stateView.isHidden {
            stateView.image = nil
        }
    }
    
    //custom override function
    override func isMyMessage() -> Bool {
        return self.viewModel?.isMyMessage ?? false
    }
}

//MARK: button function
extension SVALKMySendGiftTableViewCell{
    @IBAction func stateErrorRemarkViewButtonTouchUpInside(_ selector: UIButton) {
        var _isError = false
        var _isViolate = false
        if let _svMsgStatus = self.viewModel?.getSVMessageStatus() {
            _isError = _svMsgStatus == .error
            _isViolate = _svMsgStatus == .block
        }
        ALKConfiguration.delegateConversationRequestInfo?.messageStateRemarkButtonClicked(isError: _isError, isViolate: _isViolate)
    }
}

//MARK: textview delegate
extension SVALKMySendGiftTableViewCell : UITextViewDelegate {
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
extension SVALKMySendGiftTableViewCell{
    class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat, replyMessage: ALKMessageViewModel?) -> CGFloat {
        let _topHeightOfMessageView:CGFloat = 17.0
        let _bottomHeightOfMessageView:CGFloat = 32.0
        let _leftWidthOfMessageView:CGFloat = 44.0
        let _rightWidthOfMessageView:CGFloat = 74.0
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
