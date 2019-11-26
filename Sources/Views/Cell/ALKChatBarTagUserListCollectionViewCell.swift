//
//  ALKChatBarTagUserListCollectionViewCell.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 26/11/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

protocol ALKChatBarTagUserListCollectionViewCellDelegate : class {
    func didItemCloseButtonClicked(index:IndexPath?)
}

class ALKChatBarTagUserListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var labTitle: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    
    var delegate:ALKChatBarTagUserListCollectionViewCellDelegate?
    var index:IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.viewContent.layer.borderWidth = 1
        self.viewContent.layer.borderColor = UIColor.init(207, green: 207, blue: 207)?.cgColor
    }

    @IBAction func closeButtonTouchUpInside(_ sender: Any) {
        self.delegate?.didItemCloseButtonClicked(index:self.index)
    }
}
