//
//  ALKMessageCell.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

final class ALKInformationCell: UITableViewCell {

    var configuration = ALKConfiguration()

    fileprivate var messageView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 12.0)
        tv.isEditable = false
        tv.backgroundColor = .clear
        tv.isSelectable = false
        tv.isScrollEnabled = false
        tv.isUserInteractionEnabled = false
        tv.textAlignment = .center
        return tv
    }()

    fileprivate var bubbleView: UIView = {
        let bv = UIView()
        bv.backgroundColor = UIColor.clear
        bv.layer.cornerRadius = 12.5
        bv.layer.borderColor = UIColor.ALKSVGreyColor229().cgColor
        bv.layer.borderWidth = 1.0
        bv.isUserInteractionEnabled = false
        return bv
    }()

    func setConfiguration(configuration:ALKConfiguration) {
       self.configuration = configuration
    }

    class func topPadding() -> CGFloat {
        return 8
    }

    class func bottomPadding() -> CGFloat {
        return 8
    }

    class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {

        let widthNoPadding: CGFloat = 300
        var messageHeigh: CGFloat = 0
        if let message = viewModel.message {

            let nomalizedMessage = message.replacingOccurrences(of: " ", with: "d")

            let rect = (nomalizedMessage as NSString).boundingRect(with: CGSize.init(width: widthNoPadding, height: CGFloat.greatestFiniteMagnitude),
                                                                   options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                                   attributes: [NSAttributedString.Key.font:UIFont.font(.bold(size: 12))],
                                                                   context: nil)
            messageHeigh = rect.height + 17

            messageHeigh = ceil(messageHeigh)
        }

        return topPadding()+messageHeigh+bottomPadding()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate var viewModel: ALKMessageViewModel?

    func update(viewModel: ALKMessageViewModel) {

        self.viewModel = viewModel

        messageView.text = viewModel.message
    }

    fileprivate func setupConstraints() {

        contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        bubbleView.backgroundColor = configuration.conversationViewCustomCellBackgroundColor
        messageView.textColor = configuration.conversationViewCustomCellTextColor
        contentView.addViewsForAutolayout(views: [messageView,bubbleView])
        contentView.bringSubviewToFront(messageView)

        messageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        messageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        messageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20).isActive = true
        messageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20).isActive = true
        messageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        messageView.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true

        bubbleView.centerXAnchor.constraint(equalTo: messageView.centerXAnchor).isActive = true
        bubbleView.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 4).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -4).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -10).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: 10).isActive = true

    }
}
