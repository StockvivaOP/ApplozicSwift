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

class SVALKFriendMessageTableViewCell: ALKChatBaseCell<ALKMessageViewModel> {

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
