//
//  SVALKBaseMessageTableViewCell.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 11/6/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import UIKit

class SVALKBaseMessageTableViewCell: ALKChatBaseCell<ALKMessageViewModel> {

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//MARK: - message menu control
extension SVALKBaseMessageTableViewCell{
    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
    }
    
    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
    }
}
