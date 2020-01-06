//
//  ALKChatBaseCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Kingfisher

open class ALKChatBaseCell<T>: ALKBaseCell<T>, Localizable {

    var clientChannelKey: String?
    var localizedStringFileName: String!
    var systemConfig:ALKConfiguration?
    var delegateCellRequestInfo:ConversationCellRequestInfoDelegate?
    var delegateConversationMessageBoxAction:ConversationMessageBoxActionDelegate?

    public func setLocalizedStringFileName(_ localizedStringFileName: String) {
        self.localizedStringFileName = localizedStringFileName
    }

    fileprivate weak var chatBar: ALKChatBar?

    lazy var longPressGesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(showMenuController(withLongPress:)))
    }()

    var avatarTapped:(() -> Void)?
    
    var messageViewLinkClicked:((_ url:URL) -> Void)?

    /// Actions available on menu where callbacks
    /// needs to be send are defined here.
    enum MenuActionType {
        case reply
        case appeal(chatGroupHashID:String?, userHashID:String?, messageID:String?, message:String?)
        case pinMsg(chatGroupHashID:String?, userHashID:String?, viewModel:ALKMessageViewModel?, indexPath:IndexPath?)
        case deleteMsg(chatGroupHashID:String?, userHashID:String?, viewModel:ALKMessageViewModel?, indexPath:IndexPath?)
    }

    /// It will be invoked when one of the actions
    /// is selected.
    var menuAction: ((MenuActionType) -> Void)?

    func update(chatBar: ALKChatBar) {
        self.chatBar = chatBar
    }
    
    func isMyMessage() -> Bool {
        return false
    }
    
    func isAdminMessage() -> Bool {
        return false
    }
    
    func isDeletedMessage() -> Bool {
        return false
    }
    
    func canDeleteMessage() -> Bool {
        return false
    }
    
    @objc func menuWillShow(_ sender: Any) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
    }

    @objc func menuWillHide(_ sender: Any) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willHideMenuNotification, object: nil)

        if let chatBar = self.chatBar {
            chatBar.textView.overrideNextResponder = nil
        }
    }

    @objc func showMenuController(withLongPress sender: UILongPressGestureRecognizer) {
        if self.isDeletedMessage() {
            return
        }
        if sender.state == .began {
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillShow(_:)), name: UIMenuController.willShowMenuNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide(_:)), name: UIMenuController.willHideMenuNotification, object: nil)

            if let chatBar = self.chatBar, chatBar.textView.isFirstResponder {
                chatBar.textView.overrideNextResponder = self.contentView
            } else {
                _ = self.canBecomeFirstResponder
            }

            guard let gestureView = sender.view, let superView = sender.view?.superview else {
                return
            }

            let menuController = UIMenuController.shared

            guard !menuController.isMenuVisible, gestureView.canBecomeFirstResponder else {
                return
            }

            gestureView.becomeFirstResponder()

            var menus: [UIMenuItem] = []

            if let copyMenu = getCopyMenuItem(copyItem: self) {
                menus.append(copyMenu)
            }
            if let replyMenu = getReplyMenuItem(replyItem: self) {
                menus.append(replyMenu)
            }
            
            if let pinMsgMenu = getPinMsgMenuItem(pinMsgItem: self) {
                menus.append(pinMsgMenu)
            }
            
            if let deleteMsgMenu = getDeleteMsgMenuItem(deleteMsgItem: self) {
                menus.append(deleteMsgMenu)
            }

            if let appealMenu = getAppealMenuItem(appealItem: self) {
                menus.append(appealMenu)
            }
            
            menuController.menuItems = menus
            menuController.setTargetRect(gestureView.frame, in: superView)
            menuController.setMenuVisible(true, animated: true)
        }
    }

    override open var canBecomeFirstResponder: Bool {
        return true
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch self {
        case let menuItem as ALKCopyMenuItemProtocol where action == menuItem.selector:
            return true
        case let menuItem as ALKReplyMenuItemProtocol where action == menuItem.selector:
            return self.delegateCellRequestInfo?.isEnableReplyMenuItem() ?? false
        case let menuItem as ALKAppealMenuItemProtocol where action == menuItem.selector:
            return true
        case let menuItem as ALKPinMsgMenuItemProtocol where action == menuItem.selector:
            return self.delegateCellRequestInfo?.isEnablePinMsgMenuItem() ?? false
        case let menuItem as ALKDeleteMsgMenuItemProtocol where action == menuItem.selector:
            return true
        default:
            return false
        }
    }

    private func getCopyMenuItem(copyItem: Any) -> UIMenuItem? {
        guard let copyMenuItem = copyItem as? ALKCopyMenuItemProtocol else {
            return nil
        }
        let title =  ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_copy") ?? localizedString(forKey: "Copy", withDefaultValue: SystemMessage.LabelName.Copy, fileName: localizedStringFileName)
        let copyMenu = UIMenuItem(title: title, action: copyMenuItem.selector)
        return copyMenu
    }

    private func getReplyMenuItem(replyItem: Any) -> UIMenuItem? {
        guard let replyMenuItem = replyItem as? ALKReplyMenuItemProtocol else {
            return nil
        }
        let title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_reply") ?? localizedString(forKey: "Reply", withDefaultValue: SystemMessage.LabelName.Reply, fileName: localizedStringFileName)
        let replyMenu = UIMenuItem(title: title, action: replyMenuItem.selector)
        return replyMenu
    }
    
    private func getAppealMenuItem(appealItem: Any) -> UIMenuItem? {
        guard let appealMenuItem = appealItem as? ALKAppealMenuItemProtocol else {
            return nil
        }
        let title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_report") ?? localizedString(forKey: "Appeal", withDefaultValue: SystemMessage.LabelName.Appeal, fileName: localizedStringFileName)
        let appealMenu = UIMenuItem(title: title, action: appealMenuItem.selector)
        return appealMenu
    }
    
    private func getPinMsgMenuItem(pinMsgItem: Any) -> UIMenuItem? {
        guard let pinMsgMenuItem = pinMsgItem as? ALKPinMsgMenuItemProtocol else {
            return nil
        }
        let title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_pin") ?? localizedString(forKey: "PinMsg", withDefaultValue: SystemMessage.LabelName.PinMsg, fileName: localizedStringFileName)
        let pinMsgMenu = UIMenuItem(title: title, action: pinMsgMenuItem.selector)
        return pinMsgMenu
    }

    private func getDeleteMsgMenuItem(deleteMsgItem: Any) -> UIMenuItem? {
        guard let deleteMsgMenuItem = deleteMsgItem as? ALKDeleteMsgMenuItemProtocol else {
            return nil
        }
        let title = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_delete") ?? localizedString(forKey: "DeleteMsg", withDefaultValue: SystemMessage.LabelName.DeleteMsg, fileName: localizedStringFileName)
        let deleteMsgMenu = UIMenuItem(title: title, action: deleteMsgMenuItem.selector)
        return deleteMsgMenu
    }
}

// MARK: - ALKCopyMenuItemProtocol
@objc protocol ALKCopyMenuItemProtocol {
    func menuCopy(_ sender: Any)
}

extension ALKCopyMenuItemProtocol {
    var selector: Selector {
        return #selector(menuCopy(_:))
    }
}

// MARK: - ALKAppealMenuItemProtocol
@objc protocol ALKAppealMenuItemProtocol {
    func menuAppeal(_ sender: Any)
}

extension ALKAppealMenuItemProtocol {
    var selector: Selector {
        return #selector(menuAppeal(_:))
    }
}

// MARK: - ALKReplyMenuItemProtocol
@objc protocol ALKReplyMenuItemProtocol {
    func menuReply(_ sender: Any)
}

extension ALKReplyMenuItemProtocol {
    var selector: Selector {
        return #selector(menuReply(_:))
    }
}

// MARK: - ALKPinMsgMenuItemProtocol
@objc protocol ALKPinMsgMenuItemProtocol {
    func menuPinMsg(_ sender: Any)
}

extension ALKPinMsgMenuItemProtocol {
    var selector: Selector {
        return #selector(menuPinMsg(_:))
    }
}

// MARK: - ALKDeleteMsgMenuItemProtocol
@objc protocol ALKDeleteMsgMenuItemProtocol {
    func menuDeleteMsg(_ sender: Any)
}

extension ALKDeleteMsgMenuItemProtocol {
    var selector: Selector {
        return #selector(menuDeleteMsg(_:))
    }
}

extension ALKChatBaseCell {
    func setBubbleViewImage(for style: ALKMessageStyle.BubbleStyle, isReceiverSide: Bool = false,showHangOverImage:Bool) -> UIImage? {
        var imageTitle = showHangOverImage ? "chat_bubble_red_hover":"chat_bubble_red"
        // We can rotate the above image but loading the required
        // image would be faster and we already have both the images.
        if isReceiverSide {imageTitle = showHangOverImage ? "chat_bubble_grey_hover":"chat_bubble_grey"}
        
        guard let bubbleImage = UIImage.init(named: imageTitle, in: Bundle.applozic, compatibleWith: nil)
            else {return nil}
        
        // This API is from the Kingfisher so instead of directly using
        // imageFlippedForRightToLeftLayoutDirection() we are using this as it handles
        // platform availability and future updates for us.
        let modifier = FlipsForRightToLeftLayoutDirectionImageModifier()
        return modifier.modify(bubbleImage)
        
    }
    
    func setReplyViewImage(isReceiverSide: Bool = false) -> UIImage? {
        guard let bubbleImage = UIImage.init(named: "sv_button_chatroom_reply_grey", in: Bundle.applozic, compatibleWith: nil)
            else {return nil}

        // This API is from the Kingfisher so instead of directly using
        // imageFlippedForRightToLeftLayoutDirection() we are using this as it handles
        // platform availability and future updates for us.
        if isReceiverSide {
            guard let rightBubbleImage = UIImage.init(named: "sv_button_chatroom_right_reply_grey", in: Bundle.applozic, compatibleWith: nil)
                else {return bubbleImage}
            return rightBubbleImage
        }
        return bubbleImage

    }
}
