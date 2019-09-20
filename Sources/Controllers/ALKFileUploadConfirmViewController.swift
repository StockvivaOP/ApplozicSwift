//
//  ALKFileUploadConfirmViewController.swift
//  ApplozicSwift
//
//  Created by OldPigChu on 19/9/2019.
//  Copyright © 2019 Applozic. All rights reserved.
//

import UIKit

public protocol ALKFileUploadConfirmViewControllerDelegate :class {
    func didStartUploadFiles(urls:[URL])
}

open class ALKFileUploadConfirmViewController: ALKBaseViewController {

    //ui
    private var btnClose:UIButton = {
        let view = UIButton(type: .custom)
        view.contentHorizontalAlignment = .center
        view.accessibilityIdentifier = "conversationBackButton"
        view.backgroundColor = .clear
        view.setImage(UIImage(named: "icon_close_white", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        view.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8.0)
        //view.addTarget(self, action: #selector(ALKFileUploadConfirmViewController.closeNavBarButtonSelectionNotification(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalToConstant: 30).isActive = true
        return view
    }()
    
    private var btnSend:UIButton = {
        let view = UIButton()
        view.backgroundColor = .clear
        view.setImage(UIImage(named: "send", in: Bundle.applozic, compatibleWith: nil), for: .normal)
        view.addTarget(self, action: #selector(ALKFileUploadConfirmViewController.sendButtonClickedSelectionNotification(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalToConstant: 36).isActive = true
        view.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return view
    }()
    
    private var viewContent: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var iconImage: UIImageView = {
        let imv = UIImageView()
        imv.image =  UIImage(named: "ic_alk_document", in: Bundle.applozic, compatibleWith: nil)
        imv.backgroundColor = .clear
        imv.clipsToBounds = true
        imv.widthAnchor.constraint(equalToConstant: 26).isActive = true
        imv.heightAnchor.constraint(equalToConstant: 25).isActive = true
        return imv
    }()
    
    var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ALKSVPrimaryDarkGrey()
        label.textAlignment = .center
        label.isOpaque = true
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }()
    
    //object
    var urlList:[URL] = []
    var messageType:ALKMessageType = .text
    var delegate:ALKFileUploadConfirmViewControllerDelegate?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.isCustomLeftNavBarButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.btnClose)
        self.title = ALKConfiguration.delegateSystemTextLocalizableRequestDelegate?.getSystemTextLocalizable(key: "chat_common_document") ?? "Document"
        self.btnClose.addTarget(self, action: #selector(ALKFileUploadConfirmViewController.closeNavBarButtonSelectionNotification(_:)), for: .touchUpInside)
        self.setUpView()
        self.setupContent()
    }
    
    private func setUpView(){
        self.view.backgroundColor = UIColor.white
        self.view.addViewsForAutolayout(views: [self.viewContent])
        self.viewContent.addViewsForAutolayout(views: [self.btnSend, self.iconImage, self.nameLabel])
        
        //set constraint
        self.viewContent.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        self.viewContent.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        self.viewContent.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        self.viewContent.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
        
        self.btnSend.bottomAnchor.constraint(equalTo: self.viewContent.bottomAnchor, constant: -38.0).isActive = true
        self.btnSend.trailingAnchor.constraint(equalTo: self.viewContent.trailingAnchor, constant: -11.0).isActive = true
        
        self.iconImage.centerXAnchor.constraint(equalTo: self.viewContent.centerXAnchor, constant: 0).isActive = true
        self.iconImage.topAnchor.constraint(equalTo: self.viewContent.topAnchor, constant: 46).isActive = true
        
        self.nameLabel.centerXAnchor.constraint(equalTo: self.iconImage.centerXAnchor, constant: 0).isActive = true
        self.nameLabel.topAnchor.constraint(equalTo: self.iconImage.bottomAnchor, constant: 23).isActive = true
        self.nameLabel.leadingAnchor.constraint(equalTo: self.viewContent.leadingAnchor, constant: 20).isActive = true
        self.nameLabel.trailingAnchor.constraint(equalTo: self.viewContent.trailingAnchor, constant: -20).isActive = true
    }
    
    private func setupContent(){
        guard let _firstURL = self.urlList.first else {
            self.nameLabel.text = ""
            return
        }
        //show file name
        self.nameLabel.text = _firstURL.lastPathComponent
    }
    
    @objc private func closeNavBarButtonSelectionNotification(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func sendButtonClickedSelectionNotification(_ sender: UIButton) {
        self.delegate?.didStartUploadFiles(urls: self.urlList)
        self.closeNavBarButtonSelectionNotification(self.btnClose)
    }
}
