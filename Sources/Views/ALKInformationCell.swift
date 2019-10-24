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
        tv.textContainerInset = UIEdgeInsets.zero
        tv.textContainer.lineFragmentPadding = 0
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
    
    fileprivate var bgView: UIView = {
        let bv = UIView()
        bv.backgroundColor = UIColor.clear
        bv.isUserInteractionEnabled = false
        return bv
    }()
    
    var bubbleViewTopConst:NSLayoutConstraint?
    var bubbleViewBottomConst:NSLayoutConstraint?
    
    func setConfiguration(configuration:ALKConfiguration) {
       self.configuration = configuration
    }

    class func topPadding() -> CGFloat {
        return 4
    }

    class func bottomPadding() -> CGFloat {
        return 4
    }
    
    class func bubbleViewTopPadding(isUnreadMsg:Bool = false) -> CGFloat {
        if isUnreadMsg {
            return 12.5
        }
        return 4
    }
    
    class func bubbleViewBottomPadding(isUnreadMsg:Bool = false) -> CGFloat {
        if isUnreadMsg {
            return 12.5
        }
        return 4
    }
    

    class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {

        let _isUnReadMsg = viewModel.isUnReadMessageSeparator() == true
        var _targetFontSize = UIFont.font(.bold(size: 12.0))
        if _isUnReadMsg {
            _targetFontSize = UIFont.font(.bold(size: 16.0))
        }
        
        let widthNoPadding: CGFloat = 300
        var messageHeigh: CGFloat = 0
        if let message = viewModel.message {

            let nomalizedMessage = message.replacingOccurrences(of: " ", with: "d")

            let rect = (nomalizedMessage as NSString).boundingRect(with: CGSize.init(width: widthNoPadding, height: CGFloat.greatestFiniteMagnitude),
                                                                   options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                                   attributes: [NSAttributedString.Key.font:_targetFontSize],
                                                                   context: nil)
            messageHeigh = rect.height/* + 17*/

            messageHeigh = ceil(messageHeigh)
        }

        if messageHeigh < 17 {
            messageHeigh = 17
        }
        return topPadding()+bubbleViewTopPadding(isUnreadMsg:_isUnReadMsg)+messageHeigh+bottomPadding()+bubbleViewBottomPadding(isUnreadMsg:_isUnReadMsg)
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

        if self.viewModel?.isUnReadMessageSeparator() == true{
            self.messageView.font = UIFont.systemFont(ofSize: 16.0)
            self.bubbleViewTopConst?.constant = ALKInformationCell.bubbleViewTopPadding(isUnreadMsg:true)
            self.bubbleViewBottomConst?.constant = -ALKInformationCell.bubbleViewBottomPadding(isUnreadMsg:true)
            bubbleView.backgroundColor = UIColor.clear
            bgView.backgroundColor = configuration.conversationViewCustomCellBackgroundColor
            messageView.text = viewModel.message
            bgView.isHidden = false
        }else{
            self.messageView.font = UIFont.systemFont(ofSize: 12.0)
            self.bubbleViewTopConst?.constant = ALKInformationCell.bubbleViewTopPadding()
            self.bubbleViewBottomConst?.constant = -ALKInformationCell.bubbleViewBottomPadding()
            bubbleView.backgroundColor = configuration.conversationViewCustomCellBackgroundColor
            bgView.backgroundColor = UIColor.clear
            messageView.text = viewModel.message
            bgView.isHidden = true
        }
    }

    fileprivate func setupConstraints() {

        contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        bubbleView.backgroundColor = configuration.conversationViewCustomCellBackgroundColor
        messageView.textColor = configuration.conversationViewCustomCellTextColor
        contentView.addViewsForAutolayout(views: [bgView, messageView,bubbleView])
        contentView.bringSubviewToFront(messageView)
        
        bgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        bgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        bgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        bgView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        self.bubbleViewTopConst = bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4)
        self.bubbleViewBottomConst = bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        
        self.bubbleViewTopConst?.isActive = true
        self.bubbleViewBottomConst?.isActive = true
        bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20).isActive = true
        bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20).isActive = true
        bubbleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        messageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4).isActive = true
        messageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4).isActive = true
        messageView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 10).isActive = true
        messageView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -10).isActive = true
        messageView.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
    }
}
