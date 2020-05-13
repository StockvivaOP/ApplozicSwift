//
//  SVALKConversationNavBar.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 13/5/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import UIKit

public protocol SVALKConversationNavBarDelegate {
    func getNavigationBarSubTitle() -> String?
    func didNavigationBarItemClicked(actionItem:SVALKConversationNavBar.ALKSVNavigationBarItem, sender: Any?)
}

open class SVALKConversationNavBar {
    public enum ALKSVNavigationBarItem: Int {
        case backPage = 1
        case title
        case refreshView
        case shareGroup
        case showAdminMsgOnly
        case searchMessage
        case customRightMenu
        case defaultRightMenu
        
        func getTagId() -> Int{
            return self.rawValue
        }
    }
    
    public var delegate:SVALKConversationNavBarDelegate?
    public var navigationItem:UINavigationItem?
    public var configuration: ALKConfiguration?
    public var viewModel: ALKConversationViewModel?
    
    private var loadingIndicator:ALKLoadingIndicator?
    private var navigationBar:ALKConversationNavBar?
    
    public func setUpNavigationBar(){
        guard let _navItem = self.navigationItem,
            let _configuration = self.configuration,
            let _viewModel = self.viewModel else {
            return
        }
        
        self.loadingIndicator = ALKLoadingIndicator(frame: .zero, color: _configuration.navigationBarTitleColor)
        self.navigationBar = ALKConversationNavBar(configuration: _configuration, delegate: self)
        
        //set up left view
        _navItem.titleView = self.loadingIndicator
        self.loadingIndicator?.startLoading(localizationFileName: _configuration.localizedStringFileName)
        
        _navItem.leftBarButtonItem = UIBarButtonItem(customView: self.navigationBar!)
        _viewModel.currentConversationProfile { (profile) in
            guard let profile = profile else { return }
            _navItem.titleView = nil
            self.loadingIndicator?.stopLoading()
            self.updateContent(profile: profile)
        }
        
        //set up right view
        if let _rightNavBarButton = self.getRightNavbarButton() {
            _navItem.rightBarButtonItem = UIBarButtonItem(customView: _rightNavBarButton)
        }
    }
    
    public func updateContent(profile:ALKConversationProfile? = nil){
        if let _profile = profile {
            self.navigationBar?.updateView(profile: _profile)
        }
        self.navigationBar?.updateContent()
        self.updateShowAdminMessageButtonTitle()
    }
    
    public func getRightBarItemButton(item:ALKSVNavigationBarItem) -> UIButton? {
        let _rightNavBtnGroup = self.navigationItem?.rightBarButtonItem?.customView as? UIStackView
        let _btn = _rightNavBtnGroup?.arrangedSubviews.first(where: { $0.tag == item.getTagId() } ) as? UIButton
        return _btn
    }
    
    public func getTitleViewFrame(targetDisplayView:UIView) -> CGRect?{
        if let _titleView = self.navigationBar?.profileView {
            return _titleView.frame
        }
        return nil
    }
    
    public func getConvertTitleViewFrame(targetDisplayView:UIView) -> CGRect?{
        if let _titleView = self.navigationBar?.profileView,
            let _point = self.navigationItem?.leftBarButtonItem?.customView?.convert(_titleView.frame.origin, to: targetDisplayView) {
            return CGRect(x: _point.x, y: _point.y, width: _titleView.frame.size.width, height: _titleView.frame.size.height)
        }
        return nil
    }
    
    public func hiddenGroupMuteButton(_ hidden:Bool){
        self.navigationBar?.groupMuteImage.isHidden = hidden
    }
    
    public func setShowAdminMessageButtonStatus(_ isSelected:Bool){
        if let _rightNavBtnGroup = self.navigationItem?.rightBarButtonItem?.customView as? UIStackView,
            let _showAdminBtn = _rightNavBtnGroup.arrangedSubviews.first(where: { $0.tag == ALKSVNavigationBarItem.showAdminMsgOnly.getTagId() } ) as? UIButton {
                _showAdminBtn.isSelected = isSelected
                if isSelected {
                    _showAdminBtn.setBackgroundColor(.white)
                }else{
                    _showAdminBtn.setBackgroundColor(.clear)
                }
        }
    }
    
    private func getRightNavbarButton() -> UIView? {
        guard let _configuration = self.configuration,
                !_configuration.hideRightNavBarButtonForConversationView else {
            return nil
        }
        
        let _svRightNavBtnBar: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fill
            stackView.spacing = 8
            return stackView
        }()
        
        if _configuration.isShowAdminMessageOnlyOptionInNavBar {
            let _btnShowAdminMsgOnlySize = CGSize(width: 60.0, height: 25.0)
            let notificationShowAdminMsgSelector = #selector(SVALKConversationNavBar.sendShowAdminMessageOnlyNavBarButtonSelectionNotification(_:))
            let _showAdminbutton: UIButton = UIButton(type: UIButton.ButtonType.custom)
            _showAdminbutton.tag = ALKSVNavigationBarItem.showAdminMsgOnly.getTagId() //for show admin only message
            _showAdminbutton.layer.borderColor = UIColor.white.cgColor
            _showAdminbutton.layer.borderWidth = 1.0
            _showAdminbutton.layer.cornerRadius = _btnShowAdminMsgOnlySize.height / 2.0
            _showAdminbutton.setBackgroundColor(.clear)
            _showAdminbutton.setTitleColor(.white, for: .normal)
            _showAdminbutton.setTitleColor(.ALKSVMainColorPurple(), for: .selected)
            _showAdminbutton.setFont(font: UIFont.systemFont(ofSize: 12.0))
            let _title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chatgroup_conversation_right_menu_view_admin_only") ?? ""
            _showAdminbutton.setTitle(_title, for: .normal)
            _showAdminbutton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5.0, bottom: 0, right: 5.0)
            _showAdminbutton.addTarget(self, action:notificationShowAdminMsgSelector, for: UIControl.Event.touchUpInside)
            _showAdminbutton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                _showAdminbutton.heightAnchor.constraint(equalToConstant: _btnShowAdminMsgOnlySize.height),
                _showAdminbutton.widthAnchor.constraint(equalToConstant: _btnShowAdminMsgOnlySize.width)
                ])
            _svRightNavBtnBar.addArrangedSubview(_showAdminbutton)
        }
        
        if _configuration.isShowShareGroupOptionInNavBar {
            let _btnShowShareGroupSize = CGSize(width: 24.0, height: 24.0)
            let notificationShowAdminMsgSelector = #selector(SVALKConversationNavBar.sendShowShareGroupNavBarButtonSelectionNotification(_:))
            let _showShareGroupButton: UIButton = UIButton(type: UIButton.ButtonType.custom)
            _showShareGroupButton.tag = ALKSVNavigationBarItem.shareGroup.getTagId() //for show share group
            _showShareGroupButton.setBackgroundColor(.clear)
            _showShareGroupButton.setImage(UIImage(named: "sv_button_share_white", in: Bundle.applozic, compatibleWith: nil), for: .normal)
            _showShareGroupButton.addTarget(self, action:notificationShowAdminMsgSelector, for: UIControl.Event.touchUpInside)
            _showShareGroupButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                _showShareGroupButton.heightAnchor.constraint(equalToConstant: _btnShowShareGroupSize.height),
                _showShareGroupButton.widthAnchor.constraint(equalToConstant: _btnShowShareGroupSize.width)
                ])
            _svRightNavBtnBar.addArrangedSubview(_showShareGroupButton)
        }
        
        if _configuration.isShowSearchMessageOptionInNavBar{
            let _sizeSearchMsg = CGSize(width: 24.0, height: 24.0)
            let _notificationSearchMsgSelector = #selector(SVALKConversationNavBar.sendSearchMessageNavBarButtonSelectionNotification(_:))
            let _btnSearchMsg: UIButton = UIButton(type: UIButton.ButtonType.custom)
            _btnSearchMsg.tag = ALKSVNavigationBarItem.searchMessage.getTagId()
            _btnSearchMsg.setBackgroundColor(.clear)
            _btnSearchMsg.setImage(UIImage(named: "sv_button_search_white", in: Bundle.applozic, compatibleWith: nil), for: .normal)
            _btnSearchMsg.addTarget(self, action:_notificationSearchMsgSelector, for: UIControl.Event.touchUpInside)
            _btnSearchMsg.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                _btnSearchMsg.heightAnchor.constraint(equalToConstant: _sizeSearchMsg.height),
                _btnSearchMsg.widthAnchor.constraint(equalToConstant: _sizeSearchMsg.width)
                ])
            _svRightNavBtnBar.addArrangedSubview(_btnSearchMsg)
        }
        
        if _configuration.isShowRightMenuNavBar {
            let button: UIButton = UIButton(type: UIButton.ButtonType.custom)
            button.setTitleColor(.white, for: .normal)
            _svRightNavBtnBar.addArrangedSubview(button)
            
            if let imageCustom = _configuration.conversationViewCustomRightNavBarView {
                button.tag = ALKSVNavigationBarItem.customRightMenu.getTagId() //for custom menu
                button.setImage(imageCustom, for: .normal)
                button.addTarget(self, action: #selector(SVALKConversationNavBar.sendRightNavBarButtonCustomSelectionNotification(_:)), for: UIControl.Event.touchUpInside)
            }else if let image = _configuration.rightNavBarImageForConversationView {
                button.tag = ALKSVNavigationBarItem.defaultRightMenu.getTagId() //for default menu
                button.setImage(image, for: .normal)
                button.addTarget(self, action: #selector(SVALKConversationNavBar.sendRightNavBarButtonSelectionNotification(_:)), for: UIControl.Event.touchUpInside)
            } else {
                button.tag = ALKSVNavigationBarItem.refreshView.getTagId() //for refresh button
                button.setTitle("R", for: .normal)
                button.addTarget(self, action: #selector(SVALKConversationNavBar.refreshButtonAction(_:)), for: UIControl.Event.touchUpInside)
            }
        }
        
        return _svRightNavBtnBar
    }
    
    private func updateShowAdminMessageButtonTitle(){
        if let _rightNavBtnGroup = self.navigationItem?.rightBarButtonItem?.customView as? UIStackView,
            let _showAdminBtn = _rightNavBtnGroup.arrangedSubviews.first(where: { $0.tag == ALKSVNavigationBarItem.showAdminMsgOnly.getTagId() } ) as? UIButton {
                let _title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chatgroup_conversation_right_menu_view_admin_only") ?? ""
                _showAdminBtn.setTitle(_title, for: .normal)
                
        }
    }
}

extension SVALKConversationNavBar {
    
    @objc private func sendRightNavBarButtonSelectionNotification(_ selector: UIButton) {
        self.delegate?.didNavigationBarItemClicked(actionItem: .defaultRightMenu, sender: selector)
    }
    
    @objc private func sendRightNavBarButtonCustomSelectionNotification(_ selector: UIButton) {
        self.delegate?.didNavigationBarItemClicked(actionItem: .customRightMenu, sender: selector)
    }
    
    @objc private func refreshButtonAction(_ selector: UIButton) {
        self.delegate?.didNavigationBarItemClicked(actionItem: .refreshView, sender: selector)
    }
    
    @objc private func sendShowShareGroupNavBarButtonSelectionNotification(_ selector: UIButton) {
        self.delegate?.didNavigationBarItemClicked(actionItem: .shareGroup, sender: selector)
    }
    
    @objc private func sendShowAdminMessageOnlyNavBarButtonSelectionNotification(_ selector: UIButton) {
        self.delegate?.didNavigationBarItemClicked(actionItem: .showAdminMsgOnly, sender: selector)
    }
    
    @objc private func sendSearchMessageNavBarButtonSelectionNotification(_ selector: UIButton) {
        self.delegate?.didNavigationBarItemClicked(actionItem: .searchMessage, sender: selector)
    }
}

extension SVALKConversationNavBar : NavigationBarCallbacks {
    public func backButtonTapped() {
        self.delegate?.didNavigationBarItemClicked(actionItem: .backPage, sender: self.navigationBar?.backButton)
    }
    
    public func titleTapped() {
        self.delegate?.didNavigationBarItemClicked(actionItem: .title, sender: self.navigationBar?.profileView)
    }
    
    public func getTitle() -> String? {
        return self.delegate?.getNavigationBarSubTitle()
    }
    
}
