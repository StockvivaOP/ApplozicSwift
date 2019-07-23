//
//  ALKUIConfiguration.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 13/06/18.
//

import Foundation

public struct ALKConfiguration {

    /// If enabled then tapping on navigation bar in
    /// conversation view will open the group detail screen.
    /// - NOTE: Only works in case of groups.
    public var isTapOnNavigationBarEnabled = true

    /// If enabled then tapping on the user's profile
    /// icon in group chat will open a thread with that user.
    /// - NOTE: You will see the previous messages(if there are any).
    public var isProfileTapActionEnabled = true

    /// The background color of the ALKConversationViewController.
    public var backgroundColor = UIColor(netHex: 0xf9f9f9)

    /// Hides the bottom line in the navigation bar.
    /// It will be hidden in all the ViewControllers where
    /// navigation bar is visible. Default value is true.
    public var hideNavigationBarBottomLine = true

    /// Navigation bar's background color. It will be used in all the
    /// ViewControllers where navigation bar is visible.
    public var navigationBarBackgroundColor = UIColor.ALKSVMainColorPurple()

    /// Navigation bar's tint color. It will be used in all the
    /// ViewControllers where navigation bar is visible.
    public var navigationBarItemColor = UIColor.white

    /// Navigation bar's title color. It will be used in all the
    /// ViewControllers where navigation bar is visible.
    public var navigationBarTitleColor = UIColor.white

    /// ChatBar's bottom view color. This is the view which contains
    /// all the attachment and other options.
    public var chatBarAttachmentViewBackgroundColor = UIColor.ALKSVGreyColor245()

    /// If true then all the media options in Chat bar will be hidden.
    public var hideAllOptionsInChatBar = false

    /// If true then audio option in chat bar will be hidden.
    public var hideAudioOptionInChatBar = false

    /// If true then the start new chat button will be hidden.
    public var hideStartChatButton = false

    /// Pass the name of Localizable Strings file
    public var localizedStringFileName = "Localizable"

    /// Send message icon in chat bar.
    public var sendMessageIcon = UIImage(named: "send", in: Bundle.applozic, compatibleWith: nil)

    /// Image for navigation bar right side icon in conversation view.
    public var rightNavBarImageForConversationView: UIImage?

    /// System icon for right side navigation bar in conversation view.
    public var rightNavBarSystemIconForConversationView = UIBarButtonItem.SystemItem.refresh

    /// If true then right side navigation icon in conversation view will be hidden.
    public var hideRightNavBarButtonForConversationView = false

    /// If true then back  navigation icon in conversation list will be hidden.
    public var hideBackButtonInConversationList = false

    /// conversationlist view navigation icon for right side.
    /// By default, create group icon image will be used.
    public var rightNavBarImageForConversationListView = UIImage(named: "fill_214", in: Bundle.applozic, compatibleWith: nil)

    /// If true then click action on navigation icon in conversation list view will be handled from outside
    public var handleNavIconClickOnConversationListView = false

    /// Notification name for navigation icon click in conversation list
    public var nsNotificationNameForNavIconClick = "handleNavigationItemClick"

    /// If true then line between send button and text view will be hidden.
    public var hideLineImageFromChatBar = true

    /// If true then typing status will show user names.
    public var showNameWhenUserTypesInGroup = true

    /// If true then start new conversation button shown in the empty state will be disabled
    public var hideEmptyStateStartNewButtonInConversationList = false

    /// Date cell and  information cell  background color
    public var conversationViewCustomCellBackgroundColor = UIColor.ALKSVGreyColor229()

    /// Date cell and  information cell  text color
    public var conversationViewCustomCellTextColor = UIColor.ALKSVGreyColor102()

    /// Additional information you can pass in message metadata in all the messages.
    public var messageMetadata : [AnyHashable : Any]?

    /// Status bar style. It will be used in all view controllers.
    /// Default value is lightContent.
    public var statusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            ALKBaseNavigationViewController.statusBarStyle = statusBarStyle
        }
    }

    /// If true then the all the buttons in messages of type Quick replies,
    /// Generic Cards, Lists etc. will be disabled.
    /// USAGE: It can be used in cases where your app supports multiple types
    /// of users and you want to disable the buttons for a particular type of users.
    public var disableRichMessageButtonAction = false

    /// The name of the restricted words file. Only pass the
    /// name of the file and file extension is not required.
    /// File extension of this file will be txt.
    public var restrictedWordsFileName = ""

    /// This will show info option in action sheet
    /// when a profile is tapped in group detail screen.
    /// Clicking on the option will send a notification outside.
    /// Nothing else will be done from our side.
    public var showInfoOptionInGroupDetail: Bool = false

    /// If true, contact share option in chatbar will be hidden.
    public var hideContactInChatBar: Bool = false

    /// If true, swipe action in chatcell to delete/mute conversation will be disabled.
    public var disableSwipeInChatCell: Bool = false

    //tag: stockviva - start
    //static obj
    public static let share = ALKConfiguration()
    //delegate object
    public var delegateConversationChatBarAction:ConversationChatBarActionDelegate?
    public var delegateConversationChatContentAction:ConversationChatContentActionDelegate?
    
    /// If true, contact share option in chatbar will be hidden.
    public var enableCustomeGroupDetail: Bool = false
    
    /// If true, contact share option in chatbar will be hidden.
    public var hideLocalInChatBar: Bool = false
    
    /// Conversation View background color
    public var conversationViewBackgroundColor = UIColor.ALKSVGreyColor245()
    
    /// chat view Right Nav Bar Button
    public var conversationViewCustomRightNavBarView:UIImage?
    
    /// chat box cell background color
    public var conversationViewChatBoxCustomCellBackgroundColor = UIColor.white
    /// chat box cell user name color
    public var conversationViewChatBoxDefaultAdminNameColor = UIColor.ALKSVGreyColor207()
    /// chat box cell member user name color
    public var conversationViewChatBoxDefaultMemberNameColor = UIColor.ALKSVGreyColor207()
    /// chat box cell user name color mapping
    public var chatBoxCustomCellUserNameColorMapping:[String:UIColor] = [:]
    
    //tag: stockviva - end
    
    public init() { }
}

//tag: stockviva - start
public protocol ALKViewLifeCycleDelegate: class{
    func alkViewWillAppear(_ viewController:UIViewController)
    func alkViewDidDisappear(_ viewController:UIViewController)
}

extension ALKViewLifeCycleDelegate {
    func alkViewWillAppear(_ viewController:UIViewController){/*none*/}
    func alkViewDidDisappear(_ viewController:UIViewController){/*none*/}
}

public protocol ConversationChatContentActionDelegate: ALKViewLifeCycleDelegate{
    func isShowDiscrimation(chatView:ALKConversationViewController) -> (isShow: Bool, title: String)?
    func discrimationClicked(chatView:ALKConversationViewController)
    func getJoinGroupButtonInfo(chatView:ALKConversationViewController) -> (title:String?, backgroundColor:UIColor, textColor:UIColor, rightIcon:UIImage?)
    func groupTitleViewClicked(chatView:ALKConversationViewController)
    func rightMenuClicked(chatView:ALKConversationViewController)
}

public protocol ConversationChatBarActionDelegate: class{
    func getTextViewPashHolder(chatBar:ALKChatBar) -> String?
    func isHiddenJoinGroupButton(chatBar:ALKChatBar, isHidden:Bool)
    func joinGroupButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?)
}

extension ALKConfiguration {
    
}
