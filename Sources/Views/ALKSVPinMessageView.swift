//
//  ALKSVPinMessageView.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

protocol ALKSVPinMessageViewDelegate : class {
    func didPinMessageBarClicked(pinMsgItem: SVALKPinMessageItem, viewModel: ALKMessageViewModel)
}

open class ALKSVPinMessageView: UIView, Localizable {

    private struct PaddingSetting {
        let indecator:(top:CGFloat, bottom:CGFloat, left:CGFloat, width:CGFloat) = (top:6, bottom:6, left:7, width:5)
        let title:(top:CGFloat, left:CGFloat, right:CGFloat, height:CGFloat) = (top:4, left:10, right:10, height:21)
        let newMsgIndecator:(left:CGFloat, right:CGFloat, width:CGFloat, height:CGFloat) =  (left:4, right:10, width:45, height:16.5)
        let message:(right:CGFloat, bottom:CGFloat, height:CGFloat) = (right:10, bottom:3, height:21)
    }
    
    private let viewIndecator:UIView = {
        let _view = UIView()
        _view.backgroundColor = UIColor.ALKSVStockColorRed()
        return _view
    }()
    
    private let labTitle:UILabel = {
        let _view = UILabel()
        _view.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        _view.textColor = UIColor.ALKSVStockColorRed()
        return _view
    }()
    
    private let labNewMsgIndecator:UILabel = {
        let _view = UILabel()
        _view.font = UIFont.systemFont(ofSize: 11.0, weight: .medium)
        _view.textColor = UIColor.white
        _view.backgroundColor = UIColor.ALKSVStockColorRed()
        _view.textAlignment = .center
        _view.layer.cornerRadius = 4.0
        _view.clipsToBounds = true
        return _view
    }()
    
    private let labMessage:UILabel = {
        let _view = UILabel()
        _view.font = UIFont.systemFont(ofSize: 15.0)
        _view.textColor = UIColor.ALKSVPrimaryDarkGrey()
        _view.numberOfLines = 2
        return _view
    }()
    
    private let btnClickView: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()
    
    //object
    var delegate:ALKSVPinMessageViewDelegate?
    var conversationRequestInfoDelegate:ConversationCellRequestInfoDelegate?
    var configuration: ALKConfiguration!
    var viewModel: ALKMessageViewModel!
    var pinMsgItem: SVALKPinMessageItem!
    
    private var newMsgIndecatorLabelWidthConst:NSLayoutConstraint?
    private var newMsgIndecatorLabelLeftConst:NSLayoutConstraint?
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, configuration: ALKConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        self.setUpViews()
    }

    func setUpViews(){
        let _padding = PaddingSetting()
        self.addViewsForAutolayout(views: [self.viewIndecator, self.labTitle, self.labNewMsgIndecator, self.labMessage, self.btnClickView])
        
        self.btnClickView.addTarget(self, action: #selector(self.clickViewButtonTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
        
        self.backgroundColor = UIColor.white
        self.viewIndecator.topAnchor.constraint(equalTo: self.topAnchor, constant: _padding.indecator.top).isActive = true
        self.viewIndecator.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: _padding.indecator.left).isActive = true
        self.viewIndecator.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -_padding.indecator.bottom).isActive = true
        self.viewIndecator.widthAnchor.constraint(equalToConstant: _padding.indecator.width).isActive = true
        
        self.labTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: _padding.title.top).isActive = true
        self.labTitle.leadingAnchor.constraint(equalTo: self.viewIndecator.trailingAnchor, constant: _padding.title.left).isActive = true
        self.labTitle.heightAnchor.constraint(equalToConstant: _padding.title.height).isActive = true
        
        self.labNewMsgIndecator.centerYAnchor.constraint(equalTo: self.labTitle.centerYAnchor, constant: 0).isActive = true
        
        self.labNewMsgIndecator.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -_padding.newMsgIndecator.right).isActive = true
        self.labNewMsgIndecator.heightAnchor.constraint(equalToConstant: _padding.newMsgIndecator.height).isActive = true
        self.newMsgIndecatorLabelLeftConst = self.labNewMsgIndecator.leadingAnchor.constraint(equalTo: self.labTitle.trailingAnchor, constant: _padding.newMsgIndecator.left)
        self.newMsgIndecatorLabelLeftConst?.isActive = true
        self.newMsgIndecatorLabelWidthConst = self.labNewMsgIndecator.widthAnchor.constraint(equalToConstant: _padding.newMsgIndecator.width)
        self.newMsgIndecatorLabelWidthConst?.isActive = true
        
        self.labMessage.topAnchor.constraint(equalTo: self.labTitle.bottomAnchor).isActive = true
        self.labMessage.leadingAnchor.constraint(equalTo: self.labTitle.leadingAnchor ).isActive = true
        self.labMessage.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: _padding.message.right).isActive = true
        self.labMessage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -_padding.message.bottom).isActive = true
        self.labMessage.heightAnchor.constraint(equalToConstant: _padding.message.height).isActive = true
        
        self.btnClickView.topAnchor.constraint(equalTo: self.topAnchor ).isActive = true
        self.btnClickView.leadingAnchor.constraint(equalTo: self.leadingAnchor ).isActive = true
        self.btnClickView.trailingAnchor.constraint(equalTo: self.trailingAnchor ).isActive = true
        self.btnClickView.bottomAnchor.constraint(equalTo: self.bottomAnchor ).isActive = true
        
    }
    
    func updateContent(isHiddenNewMsgIndecator:Bool, pinMsgItem: SVALKPinMessageItem, viewModel: ALKMessageViewModel){
        self.viewModel = viewModel
        self.pinMsgItem = pinMsgItem
        let _date:Date = viewModel.date
        let _message:String = viewModel.message ?? ""
        
        self.labTitle.text = (ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message") ?? "") + " " + _date.toHHmmMMMddFormat()
        
        self.isHiddenNewMessageIndecator(isHiddenNewMsgIndecator)
        
        if self.conversationRequestInfoDelegate?.isEnablePaidFeature() == false {
            self.labMessage.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_group_open_pin_msg_required_paid_user") ?? ""
        }else{
            let _msgType = viewModel.getContentTypeForPinMessage()
            if _msgType == .document {
                self.labMessage.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_document") ?? ""
            }else if _msgType == .photo {
                self.labMessage.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_photo") ?? ""
            }else if _msgType == .text {
                self.labMessage.text = _message.scAlkReplaceSpecialKey(matchInfo: ALKConfiguration.specialLinkList)
            }else{
                self.labMessage.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_not_support") ?? ""
            }
        }
    }
    
    func isHiddenNewMessageIndecator(_ isHidde:Bool){
        let _padding = PaddingSetting()
        self.labNewMsgIndecator.text = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_new_message") ?? ""
        if isHidde || self.labNewMsgIndecator.text?.count == 0 {
            self.newMsgIndecatorLabelLeftConst?.constant = 0
            self.newMsgIndecatorLabelWidthConst?.constant = 0
        }else{
            self.newMsgIndecatorLabelLeftConst?.constant = _padding.newMsgIndecator.left
            self.newMsgIndecatorLabelWidthConst?.constant = _padding.newMsgIndecator.width
        }
    }
    
    //MARK: - button
    @objc private func clickViewButtonTouchUpInside(_ sender: UIButton) {
        self.delegate?.didPinMessageBarClicked(pinMsgItem:self.pinMsgItem, viewModel:self.viewModel)
    }
}
