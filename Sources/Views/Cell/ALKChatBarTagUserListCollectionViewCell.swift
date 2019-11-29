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
    
    static func calculateCellWidth(title:String) -> CGSize {
        let _boundingBox = title.boundingRect(with: CGSize(width: 999, height: 30), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
        let _buttonWidth:CGFloat = 24.0
        let _viewLeftPadding:CGFloat = 10.0
        let _viewRightPadding:CGFloat = 5.0
        let _totalWidth = ceil(_boundingBox.width) + _viewLeftPadding + _buttonWidth + _viewRightPadding
        return CGSize(width: _totalWidth, height: 30)
    }
}
