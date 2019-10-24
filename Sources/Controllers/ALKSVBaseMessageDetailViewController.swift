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

    @IBOutlet weak var imgPageIcon: UIImageView!
    @IBOutlet weak var labPageTitle: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    
    var configuration: ALKConfiguration!
    var delegate:ALKSVMessageDetailViewControllerDelegate?
    var isViewFromPinMessage:Bool = false
    var userName:String?
    var userIconUrl:String?
    var viewModel:ALKMessageViewModel?
    private var messageheader:ALKSVMessageDetailHeaderViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up header
        self.findAndSetUpHeader()
        //set title
        if self.isViewFromPinMessage {
            self.imgPageIcon.image = UIImage(named: "sv_icon_pin", in: Bundle.applozic, compatibleWith: nil)
            self.labPageTitle.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message") ?? ""
        }else{
            self.imgPageIcon.image = UIImage(named: "sv_icon_reply", in: Bundle.applozic, compatibleWith: nil)
            self.labPageTitle.text =  ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_reply_message") ?? ""
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let _viewModel = self.viewModel {
            self.delegate?.didMessageShow(sender: self, viewModel: _viewModel, isFromPinMessage: self.isViewFromPinMessage)
        }
    }
    
    func findAndSetUpHeader(){
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
        _header.setHeader(userName: userName, userIconUrl: userIconUrl, viewModel: _viewModel)
    }
    
    //button control
    @IBAction func closeButtonTouchUpInside(_ sender: Any) {
        if self.navigationController?.popViewController(animated: true) == nil {
            self.dismiss(animated: true, completion: nil)
        }
    }

}

extension ALKSVBaseMessageDetailViewController : ALKSVMessageDetailHeaderViewControllerDelegate {
    func didUserIconClicked() {
        if let _viewModel = self.viewModel {
            self.delegate?.didUserIconClicked(sender: self, viewModel: _viewModel)
        }
    }
}
