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

    /// If true, swipe action in chatcell to delete/mute conversation will be disabled.
    public var disableSwipeInChatCell: Bool = false

    /// Use this to customize chat input bar items like attachment
    /// button icons or their visibility.
    public var chatBar = ALKChatBarConfiguration()

    /// If true, contact share option in chatbar will be hidden.
    @available(*,deprecated, message: "Use .chatBar.optionsToShow instead")
    public var hideContactInChatBar: Bool = false {
        didSet {
            guard hideContactInChatBar else { return }
            chatBar.optionsToShow = .some([.gallery, .camera, .file])
        }
    }

    /// If true then all the media options in Chat bar will be hidden.
    @available(*,deprecated, message: "Use .chatBar.optionsToShow instead")
    public var hideAllOptionsInChatBar = false {
        didSet {
            guard hideAllOptionsInChatBar else { return }
            chatBar.optionsToShow = .none
        }
    }

    //tag: stockviva - start
    //static obj
    //public static var share = ALKConfiguration()
    
    public enum ConversationMessageTypeForApp :String {
        case text = "text"
        case audio = "audio"
        case video = "video"
        case pdf = "pdf"
        case image = "image"
        case gif = "gif"
        case doc = "doc"
        case location = "location"
        case contact = "contact"
        case information = "information"
        case html = "html"
        case quickReply = "quickReply"
        case button = "button"
        case listTemplate = "listTemplate"
        case cardTemplate = "cardTemplate"
        case email = "email"
        case faqTemplate = "faqTemplate"
        case genericCard = "genericCard"
        case imageMessage = "imageMessage"
        case unknown = ""
        
        static func getMessageTypeString(type:ALKMessageType) -> ConversationMessageTypeForApp{
            switch type {
            case .text:
                return ConversationMessageTypeForApp.text
            case .photo:
                return ConversationMessageTypeForApp.image
            case .voice:
                return ConversationMessageTypeForApp.audio
            case .location:
                return ConversationMessageTypeForApp.location
            case .information:
                return ConversationMessageTypeForApp.information
            case .video:
                return ConversationMessageTypeForApp.video
            case .html:
                return ConversationMessageTypeForApp.html
            case .quickReply:
                return ConversationMessageTypeForApp.quickReply
            case .button:
                return ConversationMessageTypeForApp.button
            case .listTemplate:
                return ConversationMessageTypeForApp.listTemplate
            case .cardTemplate:
                return ConversationMessageTypeForApp.cardTemplate
            case .email:
                return ConversationMessageTypeForApp.email
            case .document:
                return ConversationMessageTypeForApp.doc
            case .contact:
                return ConversationMessageTypeForApp.contact
            case .faqTemplate:
                return ConversationMessageTypeForApp.faqTemplate
            case .genericCard:
                return ConversationMessageTypeForApp.genericCard
            case .imageMessage:
                return ConversationMessageTypeForApp.imageMessage
            }
        }
    }
    
    public enum ConversationErrorType : CaseIterable {
        case attachmentFileSizeOverLimit
        case attachmentUploadFailure
        case funcNeedPaid
        case funcNeedPaidForPinMsg
        case networkProblem
    }
    
    /// delegate for get / set system info
    public static var delegateSystemInfoRequestDelegate:SystemInfoRequestDelegate?
    
    /// delegate for get info
    public static var delegateConversationRequestInfo:ConversationRequestInfoDelegate?
    
    /// If true, system can scroll to reply org message while click
    public var enableScrollToReplyViewWhenClick: Bool = true
    
    /// If true, system will request the app to handle
    public var enableOpenLinkInApp: Bool = false
    
    /// If true, open group detail action will call into your app, refer "ConversationChatContentActionDelegate" groupTitleViewClicked
    public var enableCustomeGroupDetail: Bool = false
    
    /// If true, mic feature will disable in chat bar
    public var hideMicInChatBar: Bool = true
    
    /// If true, local option in chatbar will be hidden.
    public var hideLocalInChatBar: Bool = false
    
    /// If true, contact share option in chatbar will be hidden.
    public var hideConversationBubbleState: Bool = false
    
    /// Conversation View background color
    public var conversationViewBackgroundColor = UIColor.ALKSVGreyColor245()
    
    /// chat view Right Nav Bar Button
    public var conversationViewCustomRightNavBarView:UIImage?
    
    /// chat view Right Nav Bar Button - show admin message only
    public var isShowAdminMessageOnlyOptionInNavBar:Bool = false
    
    /// chat view Right Nav Bar Button - show share group
    public var isShowShareGroupOptionInNavBar:Bool = false
    
    /// chat view Right Nav Bar Button - show share group
    public var isShowFloatingShareGroupButton:Bool = false
    
    /// chat box cell background color
    public var conversationViewChatBoxCustomCellBackgroundColor = UIColor.white
    /// chat box cell user name color
    public var conversationViewChatBoxDefaultAdminNameColor = UIColor.ALKSVGreyColor207()
    /// chat box cell member user name color
    public var conversationViewChatBoxDefaultMemberNameColor = UIColor.ALKSVGreyColor207()
    /// chat box cell user name color mapping
    public var chatBoxCustomCellUserNameColorMapping:[String:UIColor] = [:]
    
    /// chat box special characterey detected
    public var chatBoxSpecialCharacterKeyCheckingList:[String] = ["@"]
    
    /// Attachment file max size
    public var maxUploadFileMBSize : Float = 500.0
    
    /// image gallery file control
    public var isShowVideoFile : Bool = true
    public var isAllowsMultipleSelection : Bool = false
    
    /// allow user to delete message within target second
    public var expireSecondForDeleteMessage : Double = 120.0
    
    //tag: stockviva - end
    
    public init() { }
}

//tag: stockviva - start
public protocol ConversationChatContentActionDelegate: class{
    func isShowDiscrimation(chatView:UIViewController) -> (isShow: Bool, title: String)?
    func discrimationClicked(chatView:UIViewController)
    func getJoinGroupButtonInfo(chatView:UIViewController) -> (title:String?, backgroundColor:UIColor, textColor:UIColor, rightIcon:UIImage?)
    func getGroupTitle(chatView:UIViewController)  -> String?
    func groupTitleViewClicked(chatView:UIViewController)
    func didMessageSent(type:ALKConfiguration.ConversationMessageTypeForApp, messageID:String, messageReplyID:String, message:String?, mentionUserList:[(hashID:String, name:String)]?)
    func openLink(url:URL, sourceView:UIViewController, isPushFromSourceView:Bool)
    func backPageButtonClicked(chatView:UIViewController)
    func rightMenuClicked(chatView:UIViewController)
    func showAdminMessageOnlyButtonClicked(chatView:UIViewController, button:UIButton)
    func shareGroupButtonClicked(chatView:UIViewController, button:UIButton)
    func loadingFloatingShareButton() -> UIImage?
    func loadingFloatingShareTip() -> (title:String, image:UIImage?, bgColor:UIColor, size:CGSize, titleEdgeInsets:UIEdgeInsets?, dismissSecond:Int)
    func didFloatingShareButtonClicked(chatView:UIViewController, button:UIButton)
    func didShowAdminMessageOnlyStatusChanged(result:Bool)
    func getAdditionalSendMessageForAdmin() -> String?
    func showAlert(type:ALKConfiguration.ConversationErrorType)
    func isAdminUser(_ userHashId:String?) -> Bool
    func didUserProfileIconClicked(sender:UIViewController, viewModel:ALKMessageViewModel)
    //pin message
    func didPinMessageCloseButtonClicked(pinMsgUuid:String?, viewModel:ALKMessageViewModel)
    func didPinMessageShow(sender:UIViewController, viewModel:ALKMessageViewModel)
    func didPinMessageClicked()
    //join our group
    func joinOurGroupButtonClicked(viewModel:ALKMessageViewModel?)
    func isHiddenFullScreenLoading(_ isHidden:Bool)
    func messageHadDeleted(viewModel:ALKMessageViewModel?, indexPath:IndexPath?)
}

public protocol ConversationChatBarActionDelegate: class{
    func getTextViewPashHolder(chatBar:ALKChatBar) -> String?
    func isHiddenJoinGroupButton(chatBar:ALKChatBar, isHidden:Bool)
    func isHiddenBlockChatButton(chatBar:ALKChatBar, isHidden:Bool)
    func joinGroupButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?)
    func blockChatButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?)
    //did user entered special character key
    func didUserEnteredSpecialCharacterKey(key:String)
}

public protocol ChatBarRequestActionDelegate: class{
    func chatBarRequestGetTextViewPashHolder(chatBar:ALKChatBar) -> String?
    func chatBarRequestIsHiddenJoinGroupButton(chatBar:ALKChatBar, isHidden:Bool)
    func chatBarRequestIsHiddenBlockChatButton(chatBar:ALKChatBar, isHidden:Bool)
    func chatBarRequestJoinGroupButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?)
    func chatBarRequestBlockChatButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?)
    func chatBarRequestUserEnteredSpecialCharacterKeyDetected(key:String)
}

public protocol ConversationMessageBoxActionDelegate: class{
    func didMenuAppealClicked(chatGroupHashID:String, userHashID:String, messageID:String, message:String?)
    func didMenuPinMsgClicked(chatGroupHashID:String, userHashID:String?, viewModel:ALKMessageViewModel?, indexPath:IndexPath?)
    func didMenuDeleteMsgClicked(chatGroupHashID:String, userHashID:String?, viewModel:ALKMessageViewModel?, indexPath:IndexPath?)
}

public protocol ConversationCellRequestInfoDelegate: class{
    func isEnableReplyMenuItem() -> Bool
    func isEnablePinMsgMenuItem() -> Bool
    func isEnablePaidFeature() -> Bool
    func requestToShowAlert(type:ALKConfiguration.ConversationErrorType) //response
    func updateMessageModelData(messageModel:ALKMessageViewModel?, isUpdateView:Bool) //response
    func isAdminUserMessage(userHashId:String?) -> Bool
}

public protocol ConversationRequestInfoDelegate: class{
    func isShowJoinOurGroupButton(viewModel:ALKMessageViewModel?) -> Bool
    //validate message
    func validateMessageBeforeSend(message:String?, completed:@escaping ((_ isPass:Bool, _ error:Error?) -> ()))
    //show action for remark button
    func messageStateRemarkButtonClicked(isError:Bool, isViolate:Bool)
}

public protocol SystemInfoRequestDelegate: class{
    func getDevicePlatform() -> String?
    func getAppVersionName() -> String?
    func getSystemLocaleName() -> String
    func getSystemTextLocalizable(key:String) -> String?
    func logging(isDebug:Bool, message:String)
    func getLoginUserHashId() -> String?
}

extension ALKConfiguration {
    
}
