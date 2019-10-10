//
//  ALKSVMessageDetailViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

class ALKSVMessageDetailViewController: ALKSVBaseMessageDetailViewController {

    @IBOutlet weak var tvMessageContent: ALKTextView!
    var messageViewLinkClicked:((_ url:URL) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tvMessageContent.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                                    .underlineStyle: NSUnderlineStyle.single.rawValue]
        self.tvMessageContent.delegate = self
        //set content
        self.updateContent()
    }
    
    func updateContent(){
        self.tvMessageContent.text = self.viewModel?.message ?? ""
    }
    
}

extension ALKSVMessageDetailViewController : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let _isOpenInApp = self.configuration.enableOpenLinkInApp
        if _isOpenInApp {
            self.messageViewLinkClicked?(URL)
        }
        return !_isOpenInApp
    }
}
