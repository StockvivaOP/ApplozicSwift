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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set content
        self.updateContent()
    }
    
    func updateContent(){
        self.tvMessageContent.text = self.viewModel?.message ?? ""
    }
}
