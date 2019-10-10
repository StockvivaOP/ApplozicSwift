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
    
    var delegate:ALKSVMessageDetailHeaderViewControllerDelegate?
    var userName:String?
    var userIconUrl:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func setHeader(userName:String?, userIconUrl:String?, viewModel:ALKMessageViewModel){
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.btnUserIcon.kf.setImage(with: resource, for: .normal, placeholder: placeHolder)
        }else if let urlStr = userIconUrl, let url = URL(string: urlStr) {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            self.btnUserIcon.kf.setImage(with: resource, for: .normal, placeholder: placeHolder)
        } else {
            self.btnUserIcon.setImage(placeHolder, for: .normal)
        }
        
        self.labUserName.text = viewModel.displayName ?? userName ?? ""
        self.labMessageDate.text = viewModel.date.toHHmmMMMddFormat()
    }
    

    @IBAction func userIconButtonTouchUpInside(_ sender: Any) {
        self.delegate?.didUserIconClicked()
    }
}
