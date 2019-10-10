//
//  ALKSVPinMessageView.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 3/10/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

protocol ALKSVPinMessageViewDelegate : class {
    func didPinMessageClicked(userName:String?, userIconUrl:String?, viewModel: ALKMessageViewModel)
    func closeButtonClicked(viewModel: ALKMessageViewModel)
}

open class ALKSVPinMessageView: UIView, Localizable {

    private struct PaddingSetting {
        let indecator:(top:CGFloat, bottom:CGFloat, left:CGFloat, width:CGFloat) = (top:6, bottom:6, left:7, width:5)
        let title:(top:CGFloat, left:CGFloat, right:CGFloat, height:CGFloat) = (top:4, left:10, right:10, height:21)
        let message:(bottom:CGFloat, height:CGFloat) = (bottom:3, height:21)
        let closeButton:(top:CGFloat, bottom:CGFloat, right:CGFloat, width:CGFloat, height:CGFloat) = (top:13, bottom:13, right:14, width:24, height:24)
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
    
    private let labMessage:UILabel = {
        let _view = UILabel()
        _view.font = UIFont.systemFont(ofSize: 15.0)
        _view.textColor = UIColor.ALKSVPrimaryDarkGrey()
        return _view
    }()
    
    private let btnClickView: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()
    
    private let btnClose: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "sv_button_close_blackgray", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        return button
    }()
    
    //object
    var userName:String?
    var userIconUrl:String?
    var delegate:ALKSVPinMessageViewDelegate?
    var conversationRequestInfoDelegate:ConversationCellRequestInfoDelegate?
    var configuration: ALKConfiguration!
    var viewModel: ALKMessageViewModel!
    
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
        self.addViewsForAutolayout(views: [self.viewIndecator, self.labTitle, self.labMessage, self.btnClickView, self.btnClose])
        
        self.btnClickView.addTarget(self, action: #selector(self.clickViewButtonTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
        self.btnClose.addTarget(self, action: #selector(self.closeButtonTouchUpInside(_:)), for: UIControl.Event.touchUpInside)
        
        self.backgroundColor = UIColor.white
        self.viewIndecator.topAnchor.constraint(equalTo: self.topAnchor, constant: _padding.indecator.top).isActive = true
        self.viewIndecator.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: _padding.indecator.left).isActive = true
        self.viewIndecator.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -_padding.indecator.bottom).isActive = true
        self.viewIndecator.widthAnchor.constraint(equalToConstant: _padding.indecator.width).isActive = true
        
        self.labTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: _padding.title.top).isActive = true
        self.labTitle.leadingAnchor.constraint(equalTo: self.viewIndecator.trailingAnchor, constant: _padding.title.left).isActive = true
        self.labTitle.trailingAnchor.constraint(equalTo: self.btnClose.leadingAnchor, constant: -_padding.title.right).isActive = true
        self.labTitle.heightAnchor.constraint(equalToConstant: _padding.title.height).isActive = true
        
        self.labMessage.topAnchor.constraint(equalTo: self.labTitle.bottomAnchor).isActive = true
        self.labMessage.leadingAnchor.constraint(equalTo: self.labTitle.leadingAnchor ).isActive = true
        self.labMessage.trailingAnchor.constraint(equalTo: self.labTitle.trailingAnchor ).isActive = true
        self.labMessage.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -_padding.message.bottom).isActive = true
        self.labMessage.heightAnchor.constraint(equalToConstant: _padding.message.height).isActive = true
        
        self.btnClickView.topAnchor.constraint(equalTo: self.topAnchor ).isActive = true
        self.btnClickView.leadingAnchor.constraint(equalTo: self.leadingAnchor ).isActive = true
        self.btnClickView.trailingAnchor.constraint(equalTo: self.trailingAnchor ).isActive = true
        self.btnClickView.bottomAnchor.constraint(equalTo: self.bottomAnchor ).isActive = true
        
        self.btnClose.topAnchor.constraint(equalTo: self.topAnchor, constant: _padding.closeButton.top).isActive = true
        self.btnClose.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -_padding.closeButton.right).isActive = true
        self.btnClose.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -_padding.closeButton.bottom).isActive = true
        self.btnClose.widthAnchor.constraint(equalToConstant: _padding.closeButton.width).isActive = true
        self.btnClose.heightAnchor.constraint(equalToConstant: _padding.closeButton.height).isActive = true
    }
    
    func updateContent(userName:String?, userIconUrl:String?, viewModel: ALKMessageViewModel){
        self.viewModel = viewModel
        let _date:Date = viewModel.date
        let _message:String = viewModel.message ?? ""
        
        self.labTitle.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message") ?? "" + _date.toHHmmMMMddFormat()
        
        if self.conversationRequestInfoDelegate?.isEnablePaidFeature() == false {
            self.labTitle.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_group_open_pin_msg_required_paid_user") ?? ""
        }else{
            let _msgType = viewModel.getContentTypeForPinMessage()
            if _msgType == .document {
                self.labMessage.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_document") ?? ""
            }else if _msgType == .photo {
                self.labMessage.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_photo") ?? ""
            }else if _msgType == .text {
                self.labMessage.text = _message
            }else{
                self.labMessage.text = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin_message_not_support") ?? ""
            }
        }
    }
    
    //MARK: - button
    @objc private func clickViewButtonTouchUpInside(_ sender: UIButton) {
        self.delegate?.didPinMessageClicked(userName:self.userName, userIconUrl:self.userIconUrl, viewModel:self.viewModel)
    }
    
    @objc private func closeButtonTouchUpInside(_ sender: UIButton) {
        self.delegate?.closeButtonClicked(viewModel:self.viewModel)
    }
}
