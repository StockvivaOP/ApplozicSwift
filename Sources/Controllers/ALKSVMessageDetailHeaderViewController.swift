//
//  ALKSVMessageDetailHeaderViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 8/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit
import Kingfisher

protocol ALKSVMessageDetailHeaderViewControllerDelegate : class {
    func didUserIconClicked()
}

class ALKSVMessageDetailHeaderViewController: UIViewController {

    @IBOutlet weak var btnUserIcon: UIButton!
    @IBOutlet weak var labUserName: UILabel!
    @IBOutlet weak var labMessageDate: UILabel!
    @IBOutlet weak var labNewPinIndicator: UILabel!
    
    var delegate:ALKSVMessageDetailHeaderViewControllerDelegate?
    var userName:String?
    var userIconUrl:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func setHeader(userName:String?, userIconUrl:String?, isShowNewPinIndicator:Bool = false, viewModel:ALKMessageViewModel){
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let urlStr = userIconUrl, let url = URL(string: urlStr), urlStr.isEmpty == false {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.btnUserIcon.kf.setImage(with: resource, for: .normal, placeholder: placeHolder)
        } else if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.btnUserIcon.kf.setImage(with: resource, for: .normal, placeholder: placeHolder)
        }else {
            self.btnUserIcon.setImage(placeHolder, for: .normal)
        }
        
        if let _displayName = userName, _displayName.isEmpty == false {
            self.labUserName.text = _displayName
        }else{
            self.labUserName.text = viewModel.displayName ?? ""
        }
        self.labMessageDate.text = viewModel.date.toHHmmMMMddFormat()
        
        if let _newPinStr = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "multi_pin_new_pin_badge"), isShowNewPinIndicator && _newPinStr.count > 0 {
            self.labNewPinIndicator.isHidden = false
            self.labNewPinIndicator.text = _newPinStr
        }else{
            self.labNewPinIndicator.isHidden = true
        }
    }
    

    @IBAction func userIconButtonTouchUpInside(_ sender: Any) {
        self.delegate?.didUserIconClicked()
    }
}
