//
//  ALKSVMessageDetailViewController.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

class ALKSVMessageDetailViewController: ALKSVBaseMessageDetailViewController {

    @IBOutlet weak var tvMessageContent: UITextView!
    var messageViewLinkClicked:((_ url:URL, _ viewModel:ALKMessageViewModel?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tvMessageContent.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                                    .underlineStyle: NSUnderlineStyle.single.rawValue]
        self.tvMessageContent.delegate = self
        //set content
        self.updateContent()
    }
    
    func updateContent(){
        //self.tvMessageContent.text = self.viewModel?.message ?? ""
//        self.tvMessageContent.contentSize = self.tvMessageContent.sizeThatFits(CGSize(width: self.tvMessageContent.bounds.size.width, height: CGFloat(MAXFLOAT) ))
        self.tvMessageContent.addLink(message: self.viewModel?.message ?? "", font: self.tvMessageContent.font, matchInfo: ALKConfiguration.specialLinkList)
        let _height = TextViewSizeCalculator.height(self.tvMessageContent, maxWidth: self.tvMessageContent.bounds.size.width)
        self.tvMessageContent.contentSize = CGSize(width: self.tvMessageContent.bounds.size.width, height:_height)
    }
    
}

extension ALKSVMessageDetailViewController : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction != .invokeDefaultAction {
            return false
        }
        let _isOpenInApp = self.configuration.enableOpenLinkInApp
        if _isOpenInApp {
            self.messageViewLinkClicked?(URL, self.viewModel)
        }
        return !_isOpenInApp
    }
}
