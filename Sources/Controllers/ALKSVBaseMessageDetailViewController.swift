//
//  ALKSVBaseMessageDetailViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

protocol ALKSVMessageDetailViewControllerDelegate : class {
    func didUserIconClicked(sender:UIViewController, viewModel:ALKMessageViewModel)
    func didMessageShow(sender:UIViewController, viewModel:ALKMessageViewModel, isFromPinMessage:Bool)
}

class ALKSVBaseMessageDetailViewController: UIViewController {
    
    @IBOutlet weak var svContent: UIStackView!
    @IBOutlet weak var vTitle: UIView!
    @IBOutlet weak var vBigTitle: UIView!
    @IBOutlet weak var vSubTitle: UIView!
    @IBOutlet weak var vPinMsgCheckImg: UIView!
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var vBottomAction: UIView!
    @IBOutlet weak var imgPromotion: UIImageView!
    
    @IBOutlet weak var imgPageIcon: UIImageView!
    @IBOutlet weak var labPageTitle: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnBgClose: UIButton!
    
    @IBOutlet weak var labBigTitle: UILabel!
    @IBOutlet weak var labSubTitle: UILabel!
    @IBOutlet weak var imgPinMsgCheck: UIImageView!
    @IBOutlet weak var btnGoToChatgroup: UIButton!
    
    var configuration: ALKConfiguration!
    var delegate:ALKSVMessageDetailViewControllerDelegate?
    var isViewFromPinMessage:Bool = false
    var userName:String?
    var userIconUrl:String?
    var viewModel:ALKMessageViewModel?
    var isShowPromotionImage:Bool = false
    
    var isWelcomeUserJoinMode:Bool = false
    var bigTitle:String?
    var subTitle:String?
    
    private var messageheader:ALKSVMessageDetailHeaderViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up header
        self.findAndSetUpHeader(isShowNewPinIndicator: isWelcomeUserJoinMode)
        
        if isWelcomeUserJoinMode {
            self.vTitle.isHidden = true
            self.btnBgClose.isHidden = false
            self.vBigTitle.isHidden = self.bigTitle?.count ?? 0 > 0
            self.labBigTitle.text = self.bigTitle
            self.vSubTitle.isHidden = self.subTitle?.count ?? 0 > 0
            self.labSubTitle.text = self.subTitle
            if let _goToCGStr = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "dialog_chatgroup_promotional_pin_dialog_view_group_btn") {
                self.vBottomAction.isHidden = false
                self.btnGoToChatgroup.setTitle(_goToCGStr, for: .normal)
            }else{
                self.vBottomAction.isHidden = true
            }
            //hidden when no message content
            self.vContent.isHidden = self.viewModel == nil
            self.vPinMsgCheckImg.isHidden = self.vContent.isHidden
            self.hiddenPromotionImage(true)
        }else{
            self.vTitle.isHidden = false
            self.btnBgClose.isHidden = true
            self.vBigTitle.isHidden = true
            self.vSubTitle.isHidden = true
            self.vPinMsgCheckImg.isHidden = true
            self.vBottomAction.isHidden = true
            self.vContent.isHidden = false
            self.hiddenPromotionImage(!self.isShowPromotionImage)
            
            //set title
            if self.isViewFromPinMessage {
                self.imgPageIcon.image = UIImage(named: "sv_icon_pin", in: Bundle.applozic, compatibleWith: nil)
                self.labPageTitle.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message") ?? ""
            }else{
                self.imgPageIcon.image = UIImage(named: "sv_icon_reply", in: Bundle.applozic, compatibleWith: nil)
                self.labPageTitle.text =  ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_reply_message") ?? ""
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _viewModel = self.viewModel {
            self.delegate?.didMessageShow(sender: self, viewModel: _viewModel, isFromPinMessage: self.isViewFromPinMessage)
        }
    }
    
    func findAndSetUpHeader(isShowNewPinIndicator:Bool = false){
        //find header
        for _vc in self.children {
            if let _header = _vc as? ALKSVMessageDetailHeaderViewController{
                self.messageheader = _header
            }
        }
        
        guard let _header = self.messageheader, let _viewModel = self.viewModel else {
            //no header or no model
            return
        }
        _header.delegate = self
        _header.setHeader(userName: userName, userIconUrl: userIconUrl, isShowNewPinIndicator:isShowNewPinIndicator, viewModel: _viewModel)
    }
    
    func hiddenPromotionImage(_ isHidden:Bool){
        self.imgPromotion.isHidden = isHidden
    }
    
    //button control
    @IBAction func closeButtonTouchUpInside(_ sender: Any) {
        if self.navigationController?.popViewController(animated: true) == nil {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func gotoChatGroupButtonTouchUpInside(_ sender: Any) {
        self.closeButtonTouchUpInside(sender)
    }
}

extension ALKSVBaseMessageDetailViewController : ALKSVMessageDetailHeaderViewControllerDelegate {
    func didUserIconClicked() {
        if let _viewModel = self.viewModel {
            self.delegate?.didUserIconClicked(sender: self, viewModel: _viewModel)
        }
    }
}
