//
//  ALKChatBarTagStockCodeListCollectionViewCell.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 5/2/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import UIKit

class ALKChatBarTagStockCodeListCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var labTitle: UILabel!
    var index:IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.viewContent.layer.borderWidth = 1
        self.viewContent.layer.borderColor = UIColor.init(102, green: 102, blue: 102)?.cgColor
    }
    
    static func calculateCellWidth(title:String) -> CGSize {
        let _boundingBox = title.boundingRect(with: CGSize(width: 999, height: 24), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
        let _viewLeftPadding:CGFloat = 16.0
        let _viewRightPadding:CGFloat = 16.0
        let _totalWidth = ceil(_boundingBox.width) + _viewLeftPadding + _viewRightPadding
        return CGSize(width: _totalWidth, height: 40)
    }
}
