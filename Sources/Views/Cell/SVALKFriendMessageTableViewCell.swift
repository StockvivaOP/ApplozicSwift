//
//  SVALKFriendMessageTableViewCell.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 28/5/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import Applozic

protocol SVALKFriendMessageTableViewCellDelegate {
    
}

class SVALKFriendMessageTableViewCell: SVALKBaseMessageTableViewCell {

    let Default_MessageContent_Font:UIFont = UIFont.systemFont(ofSize: 16)
    
    //base message view item
    @IBOutlet weak var viewUserImage: UIView!
    @IBOutlet weak var imgUserImage: UIImageView!
    @IBOutlet weak var btnSendGift: UIButton!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var imgContentBg: UIImageView!
    @IBOutlet weak var labUserName: UILabel!
    @IBOutlet weak var tvMessage: ALKTextView!
    @IBOutlet weak var timeLabel: UILabel!

    //reply view
    @IBOutlet weak var viewReply: UIView!
    @IBOutlet weak var imgReplyBg: UIImageView!
    @IBOutlet weak var imgReplyIndicator: UIImageView!
    @IBOutlet weak var labReplyUserName: UILabel!
    @IBOutlet weak var labReplyMessageIcon: UIImageView!
    @IBOutlet weak var labReplyMessage: UILabel!
    @IBOutlet weak var labReplyImagePreview: UIImageView!
    
    //photo view
    @IBOutlet weak var viewPhoto: UIView!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var viewPhotoOpenArea: UIView!
    @IBOutlet weak var indicatorLoadingPhoto: UIActivityIndicatorView!
    @IBOutlet weak var imgDownloadUploadIcon: UIImageView!
    
    //attachment view
    @IBOutlet weak var viewAttacment: UIView!
    @IBOutlet weak var imgAttacmentBg: UIImageView!
    @IBOutlet weak var viewAttacmentStatus: UIView!
    @IBOutlet weak var imgAttacmentIcon: UIImageView!
    @IBOutlet weak var imgAttacmentDownloadUpload: UIImageView!
    @IBOutlet weak var viewIndicatorLoadingAttacment: UIView!
    @IBOutlet weak var labAttacmentFileInfo: UILabel!
    @IBOutlet weak var labAttacmentFileName: UILabel!
    var progressAttacmentDownloadUpload: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.isHidden = true
        view.clockwise = true
        return view
    }()
    
    //join button
    @IBOutlet weak var viewJoinGroupSuggest: UIView!
    @IBOutlet weak var btnJoinGroupSuggest: UIButton!
    
    //disclaimer
    @IBOutlet weak var viewDisclaimer: UIStackView!
    @IBOutlet weak var labDisclaimer: UILabel!
    
    //block value
    public var delegate:SVALKFriendMessageTableViewCellDelegate?
    public var sendGiftButtonAction: ((ALKMessageViewModel?)->())? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

//MARK: - base message control
extension SVALKFriendMessageTableViewCell {
        
    private func setUpBaseMessageView(){
        self.viewUserImage.layer.cornerRadius = 22.5
        self.viewUserImage.layer.borderWidth = 0.5
        self.viewUserImage.layer.borderColor = UIColor.ALKSVGreyColor207().cgColor
        self.btnSendGift.layer.cornerRadius = 8.0
    }
    
    private func updateBaseMessageView(viewModel: ALKMessageViewModel){
        //set user icon
        let _placeHolderImg = UIImage.loadFromApplozic(named:"placeholder")
        if let _url = viewModel.avatarURL {
            let _resourceImg = ImageResource(downloadURL: _url, cacheKey: _url.absoluteString)
            self.imgUserImage.kf.setImage(with: _resourceImg, placeholder: _placeHolderImg)
        } else {
            self.imgUserImage.image = _placeHolderImg
        }
        
        //set send gift button
        self.btnSendGift.setTitle(ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_send_gift") ?? "", for: .normal)
        
        //set user name
        self.labUserName.text = viewModel.displayName
        if let _messageUserId = viewModel.contactId,
            let _nameLabelColor = self.systemConfig?.chatBoxCustomCellUserNameColorMapping[_messageUserId] {
            self.labUserName.textColor = _nameLabelColor
        }else{
            self.labUserName.textColor = UIColor.ALKSVOrangeColor()
        }
        
        //set message bg
        self.imgContentBg.image = UIImage.loadFromApplozic(named: "chat_bubble_grey")
        self.imgContentBg.tintColor = UIColor.white
        
        //message
        let _messageString = viewModel.message ?? ""
        let _isDeletedMsg = viewModel.getDeletedMessageInfo().isDeleteMessage
        self.tvMessage.attributedText = nil
        self.tvMessage.text = nil
        self.tvMessage.font = UIFont.systemFont(ofSize: 16)
        self.tvMessage.textColor = UIColor.ALKSVPrimaryDarkGrey()
        if _isDeletedMsg {//not normal message
            self.tvMessage.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            self.tvMessage.textColor = UIColor.ALKSVGreyColor153()
            self.tvMessage.text = _messageString
        }else{
            self.tvMessage.addLink(message: _messageString, font: self.Default_MessageContent_Font, matchInfo: ALKConfiguration.specialLinkList)
        }
        
        //time
        self.timeLabel.text = viewModel.date.toConversationViewDateFormat()
    }
    
    
}

//MARK: - button function
extension SVALKFriendMessageTableViewCell{
    //base
    @IBAction func userImageButtonTouchUpInside(_ selector: UIButton) {
        self.avatarTapped?()
    }
    
    @IBAction func sendGiftButtonTouchUpInside(_ selector: UIButton) {
        self.sendGiftButtonAction?(self.viewModel)
    }
    
    //reply
    @IBAction func replyMessageButtonTouchUpInside(_ selector: UIButton) {
    }
    
    //photo
    @IBAction func photoOpenAreaButtonTouchUpInside(_ selector: UIButton) {
    }
    
    //attachment
    @IBAction func attachmentOpenAreaButtonTouchUpInside(_ selector: UIButton) {
    }
    
    //join group suggest
    @IBAction func joinGroupSuggestButtonTouchUpInside(_ selector: UIButton) {
    }
}

extension SVALKFriendMessageTableViewCell : ALKCopyMenuItemProtocol, ALKReplyMenuItemProtocol, ALKAppealMenuItemProtocol, ALKPinMsgMenuItemProtocol, ALKDeleteMsgMenuItemProtocol, ALKBookmarkMsgMenuItemProtocol{
    func menuCopy(_ sender: Any) {
        
    }
    
    func menuReply(_ sender: Any) {
        
    }
    
    func menuAppeal(_ sender: Any) {
        
    }
    
    func menuPinMsg(_ sender: Any) {
        
    }
    
    func menuDeleteMsg(_ sender: Any) {
        
    }
    
    func menuBookmarkMsg(_ sender: Any) {
        
    }
}
