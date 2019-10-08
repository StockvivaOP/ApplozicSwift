//
//  ALKSVBaseMessageDetailViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

protocol ALKSVMessageDetailViewControllerDelegate : class {
    func didUserIconClicked(viewModel: ALKMessageViewModel)
}

class ALKSVBaseMessageDetailViewController: UIViewController {

    @IBOutlet weak var labPageTitle: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    
    var configuration: ALKConfiguration!
    var delegate:ALKSVMessageDetailViewControllerDelegate?
    var viewModel:ALKMessageViewModel?
    private var messageheader:ALKSVMessageDetailHeaderViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up header
        self.findAndSetUpHeader()
        //set title
        self.labPageTitle.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message") ?? ""
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
        _header.setHeader(viewModel: _viewModel)
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
            self.delegate?.didUserIconClicked(viewModel: _viewModel)
        }
    }
}
