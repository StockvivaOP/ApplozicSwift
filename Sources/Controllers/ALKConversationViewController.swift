//  ConversationViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Applozic
import SafariServices

// swiftlint:disable:next type_body_length
open class ALKConversationViewController: ALKBaseViewController, Localizable {

    var timerTask = Timer()

    public var viewModel: ALKConversationViewModel! {
        willSet(updatedVM) {
            guard viewModel != nil else {return}
            if updatedVM.contactId == viewModel.contactId
                && updatedVM.channelKey == viewModel.channelKey
                && updatedVM.conversationProxy == viewModel.conversationProxy {
                self.isFirstTime = false
            } else {
                self.isFirstTime = true
            }
        }
    }

    /// Make this false if you want to use custom list view controller
    public var individualLaunch = true

    public lazy var chatBar = ALKChatBar(frame: CGRect.zero, configuration: self.configuration)

    public let autocompletionView: UITableView = {
        let tableview = UITableView(frame: CGRect.zero, style: .plain)
        tableview.backgroundColor = .white
        tableview.estimatedRowHeight = 50
        tableview.rowHeight = UITableView.automaticDimension
        tableview.separatorStyle = .none
        return tableview
    }()

    var contactService: ALContactService!

    lazy var loadingIndicator = ALKLoadingIndicator(frame: .zero, color: self.configuration.navigationBarTitleColor)

    /// Check if view is loaded from notification
    private var isViewLoadedFromTappingOnNotification: Bool = false

    /// See configuration.
    private var isGroupDetailActionEnabled = true

    /// See configuration.
    private var isProfileTapActionEnabled = true

    var isFirstTime = true
    private var bottomConstraint: NSLayoutConstraint?
    private var leftMoreBarConstraint: NSLayoutConstraint?
    private var typingNoticeViewHeighConstaint: NSLayoutConstraint?
    var isJustSent: Bool = false

    //MQTT connection retry
    fileprivate var mqttRetryCount = 0
    fileprivate var maxMqttRetryCount = 3

    fileprivate let audioPlayer = ALKAudioPlayer()

    fileprivate let moreBar: ALKMoreBar = ALKMoreBar(frame: .zero)
    fileprivate lazy var typingNoticeView = TypingNotice(localizedStringFileName : configuration.localizedStringFileName)
    fileprivate var alMqttConversationService: ALMQTTConversationService!
    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    fileprivate lazy var navigationBar = ALKConversationNavBar(configuration: self.configuration, delegate: self)

    fileprivate var keyboardSize: CGRect?

    fileprivate var localizedStringFileName: String!
    fileprivate var profanityFilter: ProfanityFilter?

    fileprivate enum ActionType: String {
        case link = "link"
        case quickReply = "quick_reply"
    }

    fileprivate enum CardTemplateActionType: String {
        case link = "link"
        case submit = "submit"
        case quickReply = "quickReply"
    }

    fileprivate enum ConstraintIdentifier {
        static let contextTitleView = "contextTitleView"
        static let replyMessageViewHeight = "replyMessageViewHeight"
        static let discrimationViewHeight = "discrimationViewHeight"
        static let pinMessageView = "pinMessageView"
    }

    fileprivate enum Padding {

        enum ContextView {
            static let height: CGFloat = 100.0
        }
        enum ReplyMessageView {
            static let height: CGFloat = 50.0
        }
        enum PinMessageView {
            static let height: CGFloat = 50.0
        }
    }

    let cardTemplateMargin: CGFloat = 150

    var tableView : UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.separatorStyle   = .none
        tv.allowsSelection  = false
        tv.clipsToBounds    = true
        tv.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tv.accessibilityIdentifier = "InnerChatScreenTableView"
        tv.backgroundColor = UIColor.ALKSVGreyColor245()
        return tv
    }()

    let unreadScrollButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        let image = UIImage(named: "scrollDown", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 19
        button.isHidden = true
        return button
    }()

    open var backgroundView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.white
        return view
    }()

    open var contextTitleView: ALKContextTitleView = {
        let contextView = ALKContextTitleView(frame: CGRect.zero)
        contextView.backgroundColor = UIColor.orange
        return contextView
    }()

    open var templateView: ALKTemplateMessagesView?

    lazy open var replyMessageView: ALKReplyMessageView = {
        let view = ALKReplyMessageView(frame: CGRect.zero, configuration: configuration)
        view.delegateCellRequestInfo = self
        view.backgroundColor = UIColor.ALKSVGreyColor250()
        return view
    }()
    
    lazy open var pinMessageView: ALKSVPinMessageView = {
        let view = ALKSVPinMessageView(frame: CGRect.zero, configuration: configuration)
        view.delegate = self
        view.conversationRequestInfoDelegate = self
        view.isHidden = true
        return view
    }()

    var contentOffsetDictionary: Dictionary<AnyHashable,AnyObject>!
    
    //tag: stockviva start
    public enum ALKConversationType : CaseIterable {
        case free
        case trial
        case paid
    }
    enum ALKConversationViewScrollingState : CaseIterable {
        case idle
        case up
        case down
        
        func getDescription() -> String {
            switch self {
            case .idle:
                return "idle"
            case .up:
                return "up"
            case .down:
                return "down"
            }
        }
    }
    public var enableShowJoinGroupMode: Bool = false
    public var enableShowBlockChatMode: Bool = false
    public var conversationType: ALKConversationType = .free
    public var isUserPaid: Bool = false
    //delegate object
    public var delegateConversationChatBarAction:ConversationChatBarActionDelegate?
    public var delegateConversationChatContentAction:ConversationChatContentActionDelegate?
    public var delegateConversationMessageBoxAction:ConversationMessageBoxActionDelegate?
    private var discrimationViewHeightConstraint: NSLayoutConstraint?
    private var isViewFirstLoad: Bool = true
    private var isAutoRefreshMessage: Bool = false
    private var isViewDisappear = false
    private var isLeaveView = false
    var scrollingState:ALKConversationViewScrollingState = .idle
    var lastScrollingPoint:CGPoint = CGPoint.zero
    open var discrimationView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.ALKSVGreyColor245()
        view.setTitleColor(UIColor.ALKSVGreyColor102(), for: .normal)
        view.setFont(font: UIFont.systemFont(ofSize: 8))
        view.titleLabel?.textAlignment = .center
        return view
    }()
    
    public let unReadMessageRemindIndicatorView: UIView = {
        let _view = UIView(frame: CGRect.zero)
        _view.backgroundColor = UIColor.ALKSVStockColorRed()
        _view.layer.cornerRadius = 7.5
        _view.isHidden = true
        return _view
    }()
    //tag: stockviva end
    
    deinit {
        self.removeObserver()
    }
    
    required public init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
        self.localizedStringFileName = configuration.localizedStringFileName
        self.contactService = ALContactService()
        configurePropertiesWith(configuration: configuration)
        self.chatBar.configuration = configuration
        self.typingNoticeView = TypingNotice(localizedStringFileName: configuration.localizedStringFileName)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func viewWillLoadFromTappingOnNotification() {
        isViewLoadedFromTappingOnNotification = true
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override func addObserver() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil,
            using: { [weak self] notification in
            print("keyboard will show")

            let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            guard
                let weakSelf = self,
                weakSelf.chatBar.isTextViewFirstResponder,
                let keyboardSize = (keyboardFrameValue as? NSValue)?.cgRectValue else {
                    return
            }

            weakSelf.keyboardSize = keyboardSize

            let tableView = weakSelf.tableView

            let keyboardHeight = -1*keyboardSize.height
            if weakSelf.bottomConstraint?.constant == keyboardHeight {return}

            weakSelf.bottomConstraint?.constant = keyboardHeight

            weakSelf.view?.layoutIfNeeded()

            if tableView.isCellVisible(section: weakSelf.viewModel.messageModels.count-1, row: 0) {
                tableView.scrollToBottomByOfset(animated: false)
            } else if weakSelf.viewModel.messageModels.count > 1 && self?.isFirstTime == false {
                weakSelf.unreadScrollButton.isHidden = false
                weakSelf.hiddenUnReadMessageRemindIndicatorViewIfNeeded()
            }
        })

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil,
            using: {[weak self] (notification) in
                guard let weakSelf = self else {return}
                let view = weakSelf.view

                weakSelf.bottomConstraint?.constant = 0

                let duration = (notification
                    .userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?
                    .doubleValue ?? 0.05

                UIView.animate(withDuration: duration, animations: {
                    view?.layoutIfNeeded()
                }, completion: { (_) in
                    guard let viewModel = weakSelf.viewModel else { return }
                    viewModel.sendKeyboardDoneTyping()
                })
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "newMessageNotification"), object: nil, queue: nil, using: {
            notification in
            guard self.viewModel != nil && self.isLeaveView == false else { return }
            guard self.viewModel.isUnreadMessageMode == false else { return }
            let msgArray = notification.object as? [ALMessage]
            print("new notification received: ", msgArray?.first?.message as Any, msgArray?.count ?? "")
            guard let list = notification.object as? [Any], !list.isEmpty, self.isViewLoaded else { return }
            self.viewModel.addMessagesToList(list, isNeedOnUnreadMessageModel:self.unreadScrollButton.isHidden == false)
//            weakSelf.handlePushNotification = false
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil, queue: nil, using: {[weak self]
            _ in
            print("notification individual chat received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_DELIVERED"), object: nil, queue: nil, using: {[weak self]
            notification in
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let key = notification.object as? String
                else { return }
            weakSelf.viewModel.updateDeliveryReport(messageKey: key, status: Int32(DELIVERED.rawValue))
            print("report delievered notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_DELIVERED_READ"), object: nil, queue: nil, using: {[weak self]
            notification in
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let key = notification.object as? String
                else { return }
            weakSelf.viewModel.updateDeliveryReport(messageKey: key, status: Int32(DELIVERED_AND_READ.rawValue))
            print("report delievered and read notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_CONVERSATION_DELIVERED_READ"), object: nil, queue: nil, using: {[weak self]
            notification in
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let key = notification.object as? String
                else { return }
            weakSelf.viewModel.updateStatusReportForConversation(contactId: key, status: Int32(DELIVERED_AND_READ.rawValue))
            print("report conversation delievered and read notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_MESSAGE_SEND_STATUS"), object: nil, queue: nil, using: {[weak self]
            notification in
            print("Message sent notification received")
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let message = notification.object as? ALMessage
                else { return }
            weakSelf.viewModel.updateSendStatus(message: message)
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil, queue: nil, using: {[weak self] notification in
            NSLog("update user detail notification received")
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let userId = notification.object as? String
                else { return }
            weakSelf.updateUserDetail(userId)
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil, queue: nil, using: {[weak self] _ in
            NSLog("update group name notification received")
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            print("update group detail")
            guard weakSelf.viewModel.isGroup else { return }
            let alChannelService = ALChannelService()
            guard let key = weakSelf.viewModel.channelKey, let channel = alChannelService.getChannelByKey(key), let name = channel.name else { return }
            let profile = weakSelf.viewModel.conversationProfileFrom(contact: nil, channel: channel)
            weakSelf.navigationBar.updateView(profile: profile)
            weakSelf.newMessagesAdded()
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND_CV"), object: nil, queue: nil) { [weak self] _ in
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            let profile = weakSelf.viewModel.currentConversationProfile(completion: { (profile) in
                guard let profile = profile else { return }
                weakSelf.navigationBar.updateView(profile: profile)
            })
            if self?.isViewFirstLoad == false {
                self?.subscribeChannelToMqtt()
                if ALUserDefaultsHandler.isUserLoggedInUserSubscribedMQTT() == false {
                    self?.isAutoRefreshMessage = true
                }
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "APP_ENTER_IN_BACKGROUND_CV"), object: nil, queue: nil) { [weak self] _ in
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            weakSelf.viewModel.sendKeyboardDoneTyping()
            self?.isAutoRefreshMessage = false
            if self?.isViewFirstLoad == false {
                self?.unsubscribingChannel()
            }
        }
    }

    override func removeObserver() {

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "newMessageNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_DELIVERED"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_DELIVERED_READ"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_CONVERSATION_DELIVERED_READ"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_MESSAGE_SEND_STATUS"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND_CV"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "APP_ENTER_IN_BACKGROUND_CV"), object: nil)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isViewDisappear = false
        self.isLeaveView = false
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            tableView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        }
        //refresh nav bar content
        self.navigationBar.updateContent()
        //self.edgesForExtendedLayout = []
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
        activityIndicator.color = UIColor.lightGray
        tableView.addSubview(activityIndicator)
        addRefreshButton()
        if let listVC = self.navigationController?.viewControllers.first as? ALKConversationListViewController, listVC.isViewLoaded, individualLaunch {
            individualLaunch = false
        }
        alMqttConversationService = ALMQTTConversationService.sharedInstance()
        if individualLaunch {
            alMqttConversationService.mqttConversationDelegate = self
            alMqttConversationService.subscribeToConversation()
        }
        viewModel.delegate = self

        if self.viewModel.isGroup == true {
            let dispName = localizedString(forKey: "Somebody", withDefaultValue: SystemMessage.Chat.somebody, fileName: localizedStringFileName)
            self.setTypingNoticeDisplayName(displayName: dispName)
        } else {
            self.setTypingNoticeDisplayName(displayName: self.title ?? "")
        }

        if let templates = viewModel.getMessageTemplates() {
            templateView = ALKTemplateMessagesView(frame: CGRect.zero, viewModel: ALKTemplateMessagesViewModel(messageTemplates: templates))
        }
        templateView?.messageSelected = { [weak self] template in
            self?.viewModel.selected(template: template,metadata: self?.configuration.messageMetadata)
        }
        if self.isFirstTime {
            setupView()
            self.refreshViewController()
        }
        configureView()
        contentOffsetDictionary = Dictionary<NSObject,AnyObject>()
        self.isViewFirstLoad = false
        print("id: ", viewModel.messageModels.first?.contactId as Any)
    }

    override open func viewDidAppear(_ animated: Bool) {
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.isViewFirstLoad = true
        setupConstraints()
        //tag: stockviva
        self.viewModel.delegateConversationChatContentAction = self.delegateConversationChatContentAction
        self.tableView.scrollsToTop = false
        self.chatBar.delegate = self
        self.chatBar.setUpViewConfig()
        //tag: on / off join group button
        self.enableJoinGroupButton(self.enableShowJoinGroupMode)
        self.enableBlockChatButton(self.enableShowBlockChatMode)
        self.showPinMessageView(isHidden: true)
        self.hideReplyMessageView()
        autocompletionView.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        chatBar.setup(autocompletionView, withPrefex: "/")
        //update color
        tableView.backgroundColor = self.configuration.conversationViewBackgroundColor
        setRichMessageKitTheme()

        guard !configuration.restrictedWordsFileName.isEmpty else {
            return
        }
        do {
            profanityFilter = try ProfanityFilter(
            fileName: configuration.restrictedWordsFileName)
        } catch {
            print("Error while loading restricted words file:", error)
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.isFirstTime && tableView.isCellVisible(section: 0, row: 0) {
            self.tableView.scrollToBottomByOfset(animated: false)
            isFirstTime = false
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isViewDisappear = true
        //save for unread message
        self.saveLastReadMessageIfNeeded()
        stopAudioPlayer()
        chatBar.stopRecording()
        if individualLaunch {
            if let _ = alMqttConversationService {
                alMqttConversationService.unsubscribeToConversation()
            }
        }
        unsubscribingChannel()
        if self.isMovingFromParent {
            self.isLeaveView = true
            self.removeObserver()
        }
    }

    override func backTapped() {
        print("back tapped")
        view.endEditing(true)
        self.viewModel.sendKeyboardDoneTyping()
        self.delegateConversationChatContentAction?.backPageButtonClicked(chatView: self)
        let popVC = navigationController?.popViewController(animated: true)
        //let popVC = navigationController?.popToRootViewController(animated: true)
        if popVC == nil {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func showAccountSuspensionView() {
        let accountVC = ALKAccountSuspensionController()
        self.present(accountVC, animated: false, completion: nil)
        accountVC.closePressed = {[weak self] in
            _ = self?.navigationController?.popToRootViewController(animated: true)
        }
    }

    func setupView() {

        unreadScrollButton.isHidden = true
        self.unReadMessageRemindIndicatorView.isHidden = true
        unreadScrollButton.addTarget(self, action: #selector(unreadScrollDownAction(_:)), for: .touchUpInside)

        backgroundView.backgroundColor = configuration.backgroundColor
        prepareTable()
        prepareMoreBar()
        prepareChatBar()
        //tag: stockviva - set up discrimation view
        self.prepareDiscrimationView()
        replyMessageView.closeButtonTapped = {[weak self] _ in
            self?.viewModel.clearSelectedMessageToReply()
            self?.hideReplyMessageView()
        }
    }

    func checkUserBlock() {
        guard !viewModel.isGroup, let contactId = viewModel.contactId else { return }
        ALUserService().getUserDetail(contactId) { (contact) in
            guard let contact = contact, contact.block else {
                self.chatBar.enableChat()
                return
            }
            self.chatBar.disableChat(
                message: self.localizedString(
                    forKey: "UnblockToEnableChat",
                    withDefaultValue: SystemMessage.Information.UnblockToEnableChat,
                    fileName: self.configuration.localizedStringFileName))
        }
    }

    func isChannelLeft() {
        guard let channelKey = viewModel.channelKey, let channel = ALChannelService().getChannelByKey(channelKey) else {
            return
        }
        //TODO: This returns nil sometimes. Find a better way.
        guard let members = ALChannelService().getListOfAllUsers(inChannel: channelKey) as? [String] else {
            return
        }
        if  channel.type != 6 && channel.type != 10 && !members.contains(ALUserDefaultsHandler.getUserId()) {
            chatBar.disableChat(message: localizedString(forKey: "NotPartOfGroup", withDefaultValue: SystemMessage.Information.NotPartOfGroup, fileName: configuration.localizedStringFileName))
        } else {
            chatBar.enableChat()
        }
        if self.configuration.enableCustomeGroupDetail {
            navigationBar.disableTitleAction = false
        }else{
            // Disable group details for support group, open group and when user is not a member.
            navigationBar.disableTitleAction = channel.type == 10 || channel.type == 6 || !members.contains(ALUserDefaultsHandler.getUserId())
        }
    }

    func prepareContextView() {
        guard viewModel.isContextBasedChat else {
            toggleVisibilityOfContextTitleView(false)
            return
        }
        guard let topicDetail = viewModel.getContextTitleData() else {
            toggleVisibilityOfContextTitleView(false)
            return
        }
        contextTitleView.configureWith(value: topicDetail)
        toggleVisibilityOfContextTitleView(true)
    }

    private func toggleVisibilityOfContextTitleView(_ show: Bool) {
        contextTitleView.isHidden = !show
        let height: CGFloat = show ? Padding.ContextView.height : 0
        contextTitleView.constraint(
            withIdentifier: ConstraintIdentifier.contextTitleView)?
            .constant = height
    }

    private func setupConstraints() {

        var allViews = [backgroundView, contextTitleView, tableView, autocompletionView, moreBar, chatBar, typingNoticeView, unreadScrollButton, unReadMessageRemindIndicatorView, replyMessageView, pinMessageView, discrimationView]
        if let templateView = templateView {
            allViews.append(templateView)
        }
        view.addViewsForAutolayout(views: allViews)

        backgroundView.topAnchor.constraint(equalTo: contextTitleView.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true

        contextTitleView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contextTitleView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contextTitleView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        contextTitleView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.contextTitleView).isActive = true

        templateView?.bottomAnchor.constraint(equalTo: discrimationView.topAnchor, constant: -5.0).isActive = true
        templateView?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5.0).isActive = true
        templateView?.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -10.0).isActive = true
        templateView?.heightAnchor.constraint(equalToConstant: 45).isActive = true

        pinMessageView.topAnchor.constraint(equalTo: contextTitleView.topAnchor).isActive = true
        pinMessageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        pinMessageView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        pinMessageView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.pinMessageView).isActive = true
        
        tableView.topAnchor.constraint(equalTo: pinMessageView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: (templateView != nil) ? templateView!.topAnchor:discrimationView.topAnchor).isActive = true

        //tag: stockviva
        discrimationView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        discrimationView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        discrimationView.bottomAnchor.constraint(equalTo: autocompletionView.topAnchor,constant: 0).isActive = true
        self.discrimationViewHeightConstraint = discrimationView.heightAnchor.constraintEqualToAnchor(constant: 20, identifier: ConstraintIdentifier.discrimationViewHeight)
        self.discrimationViewHeightConstraint?.isActive = true
        
        autocompletionView.bottomAnchor
            .constraint(equalTo: typingNoticeView.topAnchor).isActive = true
        autocompletionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        autocompletionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        typingNoticeViewHeighConstaint = typingNoticeView.heightAnchor.constraint(equalToConstant: 0)
        typingNoticeViewHeighConstaint?.isActive = true

        typingNoticeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        typingNoticeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        typingNoticeView.bottomAnchor.constraint(equalTo: replyMessageView.topAnchor).isActive = true

        chatBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        chatBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomConstraint = chatBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint?.isActive = true

        replyMessageView.leadingAnchor.constraint(
            equalTo: view.leadingAnchor).isActive = true
        replyMessageView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor).isActive = true
        replyMessageView.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.replyMessageViewHeight)
            .isActive = true
        replyMessageView.bottomAnchor.constraint(
            equalTo: chatBar.topAnchor,
            constant: 0).isActive = true

        unreadScrollButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        unreadScrollButton.widthAnchor.constraint(equalToConstant: 38).isActive = true
        unreadScrollButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -18).isActive = true
        unreadScrollButton.bottomAnchor.constraint(equalTo: tableView.bottomAnchor, constant: -18).isActive = true
        
        unReadMessageRemindIndicatorView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        unReadMessageRemindIndicatorView.widthAnchor.constraint(equalToConstant: 15).isActive = true
        unReadMessageRemindIndicatorView.topAnchor.constraint(equalTo: unreadScrollButton.topAnchor, constant: -2).isActive = true
        unReadMessageRemindIndicatorView.leadingAnchor.constraint(equalTo: unreadScrollButton.leadingAnchor, constant: -2).isActive = true

        leftMoreBarConstraint = moreBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 56)
        leftMoreBarConstraint?.isActive = true
    }

    private func setupNavigation() {
        self.navigationItem.titleView = loadingIndicator
        loadingIndicator.startLoading(localizationFileName: configuration.localizedStringFileName)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBar)
        viewModel.currentConversationProfile { (profile) in
            guard let profile = profile else { return }
            self.loadingIndicator.stopLoading()
            self.navigationBar.updateView(profile: profile)
        }
    }

    private func prepareTable() {

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tableTapped(gesture:)))
        gesture.numberOfTapsRequired = 1
        tableView.addGestureRecognizer(gesture)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 8))

        self.automaticallyAdjustsScrollViewInsets = false

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
        tableView.estimatedRowHeight = 0

        tableView.register(ALKMyMessageCell.self)
        tableView.register(ALKFriendMessageCell.self)
        tableView.register(ALKMyPhotoPortalCell.self)
        tableView.register(ALKMyPhotoLandscapeCell.self)

        tableView.register(ALKFriendPhotoPortalCell.self)
        tableView.register(ALKFriendPhotoLandscapeCell.self)

        tableView.register(ALKMyVoiceCell.self)
        tableView.register(ALKFriendVoiceCell.self)
        tableView.register(ALKInformationCell.self)
        tableView.register(ALKMyLocationCell.self)
        tableView.register(ALKFriendLocationCell.self)
        tableView.register(ALKMyVideoCell.self)
        tableView.register(ALKFriendVideoCell.self)
        tableView.register(ALKMyGenericListCell.self)
        tableView.register(ALKFriendGenericListCell.self)
        tableView.register(ALKMyGenericCardCell.self)
        tableView.register(ALKFriendGenericCardCell.self)
        tableView.register(ALKFriendQuickReplyCell.self)
        tableView.register(ALKMyQuickReplyCell.self)
        tableView.register(ALKMyMessageButtonCell.self)
        tableView.register(ALKFriendMessageButtonCell.self)
        tableView.register(ALKMyListTemplateCell.self)
        tableView.register(ALKFriendListTemplateCell.self)
        tableView.register(ALKMyDocumentCell.self)
        tableView.register(ALKFriendDocumentCell.self)
        tableView.register(ALKMyDocumentCell.self)
        tableView.register(ALKMyContactMessageCell.self)
        tableView.register(ALKFriendContactMessageCell.self)
        tableView.register(SentImageMessageCell.self)
        tableView.register(ReceivedImageMessageCell.self)
        tableView.register(ReceivedFAQMessageCell.self)
        tableView.register(SentFAQMessageCell.self)
    }

    private func prepareMoreBar() {

        moreBar.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true
        moreBar.isHidden = true
        moreBar.setHandleAction { [weak self] (_) in
            self?.hideMoreBar()
        }
    }

    private func configureChatBar() {
        self.enableJoinGroupButton(self.enableShowJoinGroupMode)
        self.enableBlockChatButton(self.enableShowBlockChatMode)
        chatBar.updateWithConfig(isOpenGroup: viewModel.isOpenGroup, config: configuration)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func prepareChatBar() {
        // Update ChatBar's top view which contains send button and the text view.
        chatBar.grayView.backgroundColor = configuration.backgroundColor

        // Update background view's color which contains all the attachment options.
        chatBar.bottomGrayView.backgroundColor = configuration.chatBarAttachmentViewBackgroundColor

        chatBar.poweredByMessageLabel.attributedText =
            NSAttributedString(string: "Powered by Applozic")
        chatBar.poweredByMessageLabel.setLinkForSubstring("Applozic", withLinkHandler: {
            [weak self] _, substring in
            guard let _ = substring else {return}
            let svc = SFSafariViewController(url: URL(string:"https://Applozic.com")!)
            self?.present(svc, animated: true, completion: nil)
        })
        if viewModel.showPoweredByMessage() {chatBar.showPoweredByMessage()}
        chatBar.accessibilityIdentifier = "chatBar"
        chatBar.setComingSoonDelegate(delegate: self.view)
        chatBar.action = { [weak self] (action) in

            guard let weakSelf = self else {
                return
            }

            if case .more(_) = action {

                if weakSelf.moreBar.isHidden == true {
                    weakSelf.showMoreBar()
                } else {
                    weakSelf.hideMoreBar()
                }

                return
            }

            weakSelf.hideMoreBar()

            switch action {

            case .sendText(let button, let message):
                if message.count < 1 {
                    return
                }

                button.isUserInteractionEnabled = false
                weakSelf.viewModel.sendKeyboardDoneTyping()

                weakSelf.chatBar.clear()

                if let profanityFilter = weakSelf.profanityFilter, profanityFilter.containsRestrictedWords(text: message) {
                    let profanityTitle = weakSelf.localizedString(
                        forKey: "profaneWordsTitle",
                        withDefaultValue: SystemMessage.Warning.profaneWordsTitle,
                        fileName: weakSelf.localizedStringFileName)
                    let profanityMessage = weakSelf.localizedString(
                        forKey: "profaneWordsMessage",
                        withDefaultValue: SystemMessage.Warning.profaneWordsMessage,
                        fileName: weakSelf.localizedStringFileName)
                    let okButtonTitle = weakSelf.localizedString(
                        forKey: "OkMessage",
                        withDefaultValue: SystemMessage.ButtonName.ok,
                        fileName: weakSelf.localizedStringFileName)
                    let alert = UIAlertController(
                        title: profanityTitle,
                        message: profanityMessage,
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(
                        title: okButtonTitle,
                        style: .cancel,
                        handler: nil))
                    weakSelf.present(alert, animated: false, completion: nil)
                    button.isUserInteractionEnabled = true
                    return
                }
                weakSelf.isJustSent = true
                print("About to send this message: ", message)
                
                var _tempMsg = message
                if let _additionalMsg = self?.delegateConversationChatContentAction?.getAdditionalSendMessageForAdmin() {
                    _tempMsg = _tempMsg + _additionalMsg
                }
                
                self?.sendMessageWithHandleUnreadModel(completedBlock: {
                    weakSelf.viewModel.send(message: _tempMsg, isOpenGroup: weakSelf.viewModel.isOpenGroup, metadata:self?.configuration.messageMetadata)
                    button.isUserInteractionEnabled = true
                })
            case .chatBarTextChange:

                weakSelf.viewModel.sendKeyboardBeginTyping()

                UIView.animate(withDuration: 0.05, animations: { () in
                    weakSelf.view.layoutIfNeeded()
                }, completion: { [weak self] (_) in

                    guard let weakSelf = self else {
                        return
                    }

                    if weakSelf.tableView.isAtBottom == true && weakSelf.isJustSent == false {
                        weakSelf.tableView.scrollToBottomByOfset(animated: false)
                    }
                })
            case .sendVoice(let voice):
                self?.sendMessageWithHandleUnreadModel(completedBlock: {
                    weakSelf.viewModel.send(voiceMessage: voice as Data, metadata:self?.configuration.messageMetadata)
                })
            case .startVideoRecord:
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                        granted in
                        DispatchQueue.main.async {
                            if granted {
                                let imagePicker = UIImagePickerController()
                                imagePicker.delegate = self
                                imagePicker.allowsEditing = true
                                imagePicker.sourceType = .camera
                                imagePicker.mediaTypes = [kUTTypeMovie as String]
                                UIViewController.topViewController()?.present(imagePicker, animated: false, completion: nil)
                            } else {
                                let msg = weakSelf.localizedString(
                                    forKey: "EnableCameraPermissionMessage",
                                    withDefaultValue: SystemMessage.Camera.cameraPermission,
                                    fileName: weakSelf.localizedStringFileName)
                                ALUtilityClass.permissionPopUp(withMessage: msg, andViewController: self)
                            }
                        }
                    })
                } else {
                    let msg = weakSelf.localizedString(forKey: "CameraNotAvailableMessage", withDefaultValue: SystemMessage.Camera.CamNotAvailable, fileName: weakSelf.localizedStringFileName)
                    let title = weakSelf.localizedString(forKey: "CameraNotAvailableTitle", withDefaultValue: SystemMessage.Camera.camNotAvailableTitle, fileName: weakSelf.localizedStringFileName)
                    ALUtilityClass.showAlertMessage(msg, andTitle: title)
                }
            case .showUploadAttachmentFile:
                let _types:[String] = ["com.adobe.pdf", "public.image"]
                let _vc = ALKCVDocumentPickerViewController(documentTypes: _types, in: UIDocumentPickerMode.import)
                _vc.delegate = weakSelf
                weakSelf.present(_vc, animated: false, completion: nil)
                break
            case .showImagePicker:
                guard let vc = ALKCustomPickerViewController.makeInstanceWith(delegate: weakSelf, conversationRequestInfoDelegate:weakSelf, and: weakSelf.configuration)
                    else {
                        return
                }
                weakSelf.present(vc, animated: false, completion: nil)
            case .showLocation:
                let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mapView, bundle: Bundle.applozic)

                guard let nav = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
                guard let mapViewVC = nav.viewControllers.first as? ALKMapViewController else { return }
                mapViewVC.delegate = self
                mapViewVC.setConfiguration(weakSelf.configuration)
                self?.present(nav, animated: true, completion: {})
            case .cameraButtonClicked(let button):
                guard let vc = ALKCustomCameraViewController.makeInstanceWith(delegate: weakSelf, conversationRequestInfoDelegate: weakSelf, and: weakSelf.configuration)
                else {
                    button.isUserInteractionEnabled = true
                    return
                }
                weakSelf.present(vc, animated: false, completion: nil)
                button.isUserInteractionEnabled = true

            case .shareContact:
                weakSelf.shareContact()
            default:
                print("Not available")
            }
        }
    }

    // MARK: public Control Typing notification
    func setTypingNoticeDisplayName(displayName:String) {
        typingNoticeView.setDisplayName(displayName: displayName)
    }

    @objc func tableTapped(gesture: UITapGestureRecognizer) {
        hideMoreBar()
        view.endEditing(true)
    }

    /// Call this method after proper viewModel initialization
    public func refreshViewController() {
        viewModel.clearViewModel()
        tableView.reloadData()
        configureView()
        viewModel.prepareController()
        isFirstTime = false
    }

    func configureView() {
        setupNavigation()
        prepareContextView()
        configureChatBar()
        //Check for group left
        isChannelLeft()
        checkUserBlock()
        subscribeChannelToMqtt()
    }
    
    
    public func refreshTableView() {
        tableView.reloadData()
    }

    /// Call this before changing viewModel contents
    public func unsubscribingChannel() {
        guard viewModel != nil, alMqttConversationService != nil else { return }
        if !viewModel.isOpenGroup {
            self.alMqttConversationService.sendTypingStatus(
                ALUserDefaultsHandler.getApplicationKey(),
                userID: viewModel.contactId,
                andChannelKey: viewModel.channelKey,
                typing: false)
            self.alMqttConversationService.unSubscribe(toChannelConversation: viewModel.channelKey)
        } else {
            self.alMqttConversationService.unSubscribe(toOpenChannel: viewModel.channelKey)
        }
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        UIMenuController.shared.setMenuVisible(false, animated: true)
        hideMoreBar()
    }

    // Called from the parent VC
    public func showTypingLabel(status: Bool, userId: String) {
        /// Don't show typing status when contact is blocked
        guard
            let contact = ALContactService().loadContact(byKey: "userId", value: userId),
            !contact.block,
            !contact.blockBy
            else {
            return
        }

        if(status) {
            timerTask = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.invalidateTimerAndUpdateHeightConstraint(_:)), userInfo: nil, repeats: false)
        } else {
            timerTask.invalidate()
        }

        typingNoticeViewHeighConstaint?.constant = status ? 30:0
        view.layoutIfNeeded()
        if tableView.isAtBottom {
            tableView.scrollToBottomByOfset(animated: false)
        }

        if configuration.showNameWhenUserTypesInGroup {
            guard let name = nameForTypingStatusUsing(userId: userId) else {
                return
            }
            setTypingNoticeDisplayName(displayName: name)
        } else {
            let name = defaultNameForTypingStatus()
            setTypingNoticeDisplayName(displayName: name)
        }
    }

    @objc public func invalidateTimerAndUpdateHeightConstraint(_ timer: Timer?) {
        timerTask.invalidate()
        typingNoticeViewHeighConstaint?.constant = 0
    }

    public func sync(message: ALMessage) {
        /// Return if message is sent by loggedin user
        guard !message.isSentMessage() else { return }
        if self.viewModel.isUnreadMessageMode { return }
        guard !viewModel.isOpenGroup else {
            viewModel.syncOpenGroup(message: message)
            return
        }
        guard (message.conversationId == nil || message.conversationId != viewModel.conversationProxy?.id) else {
            return
        }
        if let groupId = message.groupId, groupId != viewModel.channelKey {
            let notificationView = ALNotificationView(alMessage: message, withAlertMessage: message.message)
            notificationView?.showNativeNotificationWithcompletionHandler({
                _ in
                self.viewModel.contactId = nil
                self.viewModel.channelKey = groupId
                self.viewModel.isFirstTime = true
                self.refreshViewController()
            })
        } else if message.groupId == nil, let contactId = message.contactId, contactId != viewModel.contactId {
            let notificationView = ALNotificationView(alMessage: message, withAlertMessage: message.message)
            notificationView?.showNativeNotificationWithcompletionHandler({
                _ in
                self.viewModel.contactId = contactId
                self.viewModel.channelKey = nil
                self.viewModel.isFirstTime = true
                self.refreshViewController()
            })
        }
    }

    public func updateDeliveryReport(messageKey: String?, contactId: String?, status: Int32?) {
        guard let key = messageKey, let status = status else {
            return
        }
        viewModel.updateDeliveryReport(messageKey: key, status: status)
    }

    public func updateStatusReport(contactId: String?, status: Int32?) {
        guard let id = contactId, let status = status else {
            return
        }
        viewModel.updateStatusReportForConversation(contactId: id, status: status)
    }

    private func defaultNameForTypingStatus() -> String {
        if self.viewModel.isGroup == true {
            return "Somebody"
        } else {
            return self.title ?? ""
        }
    }

    private func nameForTypingStatusUsing(userId: String) -> String? {
        guard let contact = contactService.loadContact(byKey: "userId", value: userId) else {
            return nil
        }
        if contact.block || contact.blockBy {
            return nil
        }
        return contact.getDisplayName()
    }

    fileprivate func subscribeChannelToMqtt() {
        let channelService = ALChannelService()
        self.alMqttConversationService.subscribeToConversation()
        if viewModel.isGroup, let groupId = viewModel.channelKey, !channelService.isChannelLeft(groupId) && !ALChannelService.isChannelDeleted(groupId) {
            if !viewModel.isOpenGroup {
                self.alMqttConversationService.subscribe(toChannelConversation: groupId)
            } else {
                self.alMqttConversationService.subscribe(toOpenChannel: groupId)
            }
        } else if !viewModel.isGroup {
            self.alMqttConversationService.subscribe(toChannelConversation: nil)
        }
        if viewModel.isGroup, ALUserDefaultsHandler.isUserLoggedInUserSubscribedMQTT() {
            self.alMqttConversationService.unSubscribe(toChannelConversation: nil)
        }

    }

    @objc func unreadScrollDownAction(_ sender: UIButton) {
        if self.viewModel.isUnreadMessageMode {//just cancel if user want to read latest message of now
            self.viewModel.clearUnReadMessageData()
            self.scrollingState = .idle
            self.lastScrollingPoint = CGPoint.zero
            ALKSVUserDefaultsControl.shared.removeLastReadMessageTime()
            self.refreshViewController()
        }
        tableView.scrollToBottom(animated: true)
        unreadScrollButton.isHidden = true
        self.unReadMessageRemindIndicatorView.isHidden = true
    }
    
    @objc func discrimationToucUpInside(_ sender: UIButton) {
        self.delegateConversationChatContentAction?.discrimationClicked(chatView: self)
    }


    func attachmentViewDidTapDownload(view: UIView, indexPath: IndexPath) {
        guard let message = viewModel.messageForRow(indexPath: indexPath) else { return }
        viewModel.downloadAttachment(message: message, view: view)
    }

    func attachmentViewDidTapUpload(view: UIView, indexPath: IndexPath) {
        guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }
        viewModel.uploadImage(view: view, indexPath: indexPath)
    }

    func attachmentUploadDidCompleteWith(response: Any?, indexPath: IndexPath) {
        viewModel.uploadAttachmentCompleted(responseDict: response, indexPath: indexPath)
    }

    func messageAvatarViewDidTap(messageVM: ALKMessageViewModel, indexPath: IndexPath) {
        // Open chat thread
        guard viewModel.isGroup && isProfileTapActionEnabled else {return}

        // Get the user id of that user
        guard let receiverId = messageVM.receiverId else {return}

        let vm = ALKConversationViewModel(contactId: receiverId, channelKey: nil, localizedStringFileName: configuration.localizedStringFileName)
        let conversationVC = ALKConversationViewController(configuration: configuration)
        conversationVC.viewModel = vm
        navigationController?.pushViewController(conversationVC, animated: true)
    }

    func menuItemSelected(action: ALKChatBaseCell<ALKMessageViewModel>.MenuActionType,
                          message: ALKMessageViewModel) {
        switch action {
        case .reply:
            print("Reply selected")
            viewModel.setSelectedMessageToReply(message)
            replyMessageView.update(message: message, configuration:self.configuration)
            showReplyMessageView()
            break;
        case .appeal(let chatGroupHashID, let userHashID, let messageID, let message):
            print("Appeal selected")
            if let _chatGroupID = chatGroupHashID,
                let _userID = userHashID,
                let _msgID = messageID {
                self.delegateConversationMessageBoxAction?.didMenuAppealClicked(chatGroupHashID:_chatGroupID, userHashID:_userID, messageID:_msgID, message:message)
            }
            break;
        case .pinMsg(let chatGroupHashID, let userHashID, let viewModel, let indexPath):
            print("PinMsg selected")
            if let _chatGroupID = chatGroupHashID,
                let _model = viewModel {
                self.delegateConversationMessageBoxAction?.didMenuPinMsgClicked(chatGroupHashID:_chatGroupID, userHashID:userHashID, viewModel: _model, indexPath:indexPath)
            }
            break;
        }
    }

    func showReplyMessageView() {
        let _height = replyMessageView.getViewHeight()
        replyMessageView.constraint(
            withIdentifier: ConstraintIdentifier.replyMessageViewHeight)?
            .constant = _height//Padding.ReplyMessageView.height
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
        self.tableView.setContentOffset(CGPoint(x: self.tableView.contentOffset.x, y: self.tableView.contentOffset.y + _height ), animated: true)
        replyMessageView.isHidden = false
        self.chatBar.hiddenLineView(true)
    }

    func hideReplyMessageView() {
        replyMessageView.constraint(
            withIdentifier: ConstraintIdentifier.replyMessageViewHeight)?
            .constant = 0
        replyMessageView.isHidden = true
        self.chatBar.hiddenLineView(true)
    }

    func scrollTo(message: ALKMessageViewModel) {
        let messageService = ALMessageService()
        guard
            let metadata = message.metadata,
            let replyId = metadata[AL_MESSAGE_REPLY_KEY] as? String
            else {return}
        let actualMessage = messageService.getALMessage(byKey: replyId).messageModel
        guard let indexPath = viewModel.getIndexpathFor(message: actualMessage)
            else {return}
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - scrollTo() - scroll to indexPath:\(indexPath.section), total section:\(self.tableView.numberOfSections)")
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)

    }

    func postGenericListButtonTapNotification(tag: Int, title: String, template: [ALKGenericListTemplate], key: String) {
        print("\(title, tag) button selected in generic list")
        var infoDict = [String: Any]()
        infoDict["buttonName"] = title
        infoDict["buttonIndex"] = tag
        infoDict["template"] = template
        infoDict["messageKey"] = key
        infoDict["userId"] = self.viewModel.contactId
        NotificationCenter.default.post(name: Notification.Name(rawValue: "GenericRichListButtonSelected"), object: infoDict)
    }

    func quickReplySelected(
        index: Int,
        title: String,
        template: [Dictionary<String, Any>],
        message: ALKMessageViewModel,
        metadata: Dictionary<String, Any>?,
        isButtonClickDisabled: Bool) {
        print("\(title, index) quick reply button selected")
        sendNotification(withName: "QuickReplyButtonSelected", buttonName: title, buttonIndex: index, template: template, messageKey: message.identifier)

        guard !isButtonClickDisabled else { return }

        /// Get message to send
        guard index <= template.count && index > 0 else { return }
        let dict = template[index - 1]
        let msg = dict["message"] as? String ?? title

        /// Use metadata
        sendQuickReply(msg, metadata: metadata)
    }

    func messageButtonSelected(
        index: Int,
        title: String,
        message: ALKMessageViewModel,
        isButtonClickDisabled: Bool) {
        guard !isButtonClickDisabled,
            let selectedButton = message.payloadFromMetadata()?[index],
            let buttonTitle = selectedButton["name"] as? String,
            buttonTitle == title
            else {
            return
        }

        guard
            let type = selectedButton["type"] as? String,
            type == "link"
            else {
                /// Submit Button
                let text = selectedButton["replyText"] as? String ?? selectedButton["name"] as! String
                submitButtonSelected(metadata: message.metadata!, text: text)
                return
        }
        linkButtonSelected(selectedButton)
    }

    func listTemplateSelected(defaultText: String?, action: ListTemplate.Action) {
        guard !configuration.disableRichMessageButtonAction else { return }
        guard let type = action.type else {
            print("Type not defined for action")
            return
        }

        switch type {
            case ActionType.link.rawValue:
                guard let urlString = action.url, let url = URL(string: urlString) else { return }
                openLink(url)

            case ActionType.quickReply.rawValue:
                let text = action.text ?? defaultText
                guard let msg = text else { return }
                sendQuickReply(msg, metadata: nil)

            default:
                print("Action type is neither \"link\" nor \"quick_reply\"")
                var infoDict = [String: Any]()
                infoDict["action"] = action
                infoDict["userId"] = self.viewModel.contactId
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ListTemplateSelected"), object: infoDict)
        }
    }

    func cardTemplateSelected(tag: Int, title: String, template: CardTemplate, message: ALKMessageViewModel) {
        guard
            message.isMyMessage == false,
            configuration.disableRichMessageButtonAction == false
        else {
                return
        }

        guard
            let buttons = template.buttons, tag < buttons.count,
            let action = buttons[tag].action,
            let payload = action.payload
        else {
            print("\(tag) Button for this card is nil unexpectedly :: \(template)")
            return
        }

        switch action.type {
        case CardTemplateActionType.link.rawValue:
            guard let urlString = payload.url, let url = URL(string: urlString) else { return }
            openLink(url)
        case CardTemplateActionType.submit.rawValue:
            var dict = [String: Any]()
            dict["formData"] = payload.formData
            dict["formAction"] = payload.formAction
            dict["requestType"] = payload.requestType
            submitButtonSelected(metadata: dict, text: payload.text ?? "")
        case CardTemplateActionType.quickReply.rawValue:
            let text = payload.title ?? buttons[tag].name
            sendQuickReply(text, metadata: nil)
        default:
            /// Action not defined. Post notification outside.
            sendNotification(withName: "GenericRichCardButtonSelected", buttonName: title, buttonIndex: tag, template: message.payloadFromMetadata() ?? [], messageKey: message.identifier)
        }
    }

    @objc func dismissContact() {
        ALPushAssist().topViewController.dismiss(animated: true, completion: nil)
    }

    func openContact(_ contact: CNContact) {
        CNContactStore().requestAccess(for: .contacts) { (granted, _) in
            if granted {
                let vc = CNContactViewController(forUnknownContact: contact)
                vc.contactStore = CNContactStore()
                let nav = UINavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissContact))
                self.present(nav, animated: true, completion: nil)
            } else {
                ALUtilityClass.permissionPopUp(withMessage: "Enable Contact permission", andViewController: self)
            }
        }
    }

    func collectionViewOffsetFromIndex(_ index: Int) -> CGFloat {

        let value = contentOffsetDictionary[index]
        let horizontalOffset = CGFloat(value != nil ? value!.floatValue : 0)
        return horizontalOffset
    }

    private func showMoreBar() {

        self.moreBar.isHidden = false
        self.leftMoreBarConstraint?.constant = 0

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] () in
            self?.view.layoutIfNeeded()
            }, completion: { [weak self] (_) in

                guard let strongSelf = self else {return}

                strongSelf.view.bringSubviewToFront(strongSelf.moreBar)
                strongSelf.view.sendSubviewToBack(strongSelf.tableView)
        })

    }

    private func sendNotification(withName: String, buttonName: String, buttonIndex: Int, template: [Dictionary<String, Any>], messageKey: String) {
        var infoDict = [String: Any]()
        infoDict["buttonName"] = title
        infoDict["buttonIndex"] = index
        infoDict["template"] = template
        infoDict["messageKey"] = messageKey
        infoDict["userId"] = self.viewModel.contactId
        NotificationCenter.default.post(name: Notification.Name(rawValue: withName), object: infoDict)
    }

    private func hideMoreBar() {

        if self.leftMoreBarConstraint?.constant == 0 {

            self.leftMoreBarConstraint?.constant = 56

            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] () in
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (_) in
                    self?.moreBar.isHidden = true
            })

        }

    }

    @objc private func showParticipantListChat() {
        guard let channelKey = viewModel.channelKey else { return }
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.createGroupChat, bundle: Bundle.applozic)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ALKCreateGroupViewController") as? ALKCreateGroupViewController {
            vc.configuration = configuration
            vc.setCurrentGroupSelected(
                groupId: channelKey,
                groupProfile: self.viewModel.groupProfileImgUrl(),
                delegate: self)
            vc.addContactMode = .existingChat
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func configurePropertiesWith(configuration: ALKConfiguration) {
        self.isGroupDetailActionEnabled = configuration.isTapOnNavigationBarEnabled
        self.isProfileTapActionEnabled = configuration.isProfileTapActionEnabled
    }

    private func sendQuickReply(_ text: String, metadata: Dictionary<String, Any>?) {
        var customMetadata = metadata ?? [String: Any]()
        guard let messageMetadata = configuration.messageMetadata as? [String: Any] else {
            viewModel.send(message: text, metadata: customMetadata)
            return
        }
        customMetadata.merge(messageMetadata) { $1 }
        viewModel.send(message: text, metadata: customMetadata)
    }

    private func postRequestUsing(url: URL, param: String) -> URLRequest? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 600
        request.httpMethod = "POST"
        guard let data = param.data(using: .utf8) else { return nil }
        request.httpBody = data
        let contentLength = String(format: "%lu", UInt(data.count))
        request.setValue(contentLength, forHTTPHeaderField: "Content-Length")
        return request
    }

    private func requestHandler(_ request: URLRequest, _ completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            print("Response is \(String(describing: response)) and error is \(String(describing: error))")
            completion(data, response, error)
        }
        task.resume()
    }

    private func openLink(_ url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }    }

    private func linkButtonSelected(_ selectedButton: Dictionary<String, Any>) {
        guard
            let urlString = selectedButton["url"] as? String,
            let url = URL(string: urlString)
        else {
            return
        }
        openLink(url)
    }

    private func submitButtonResponse(request: URLRequest) {
        activityIndicator.startAnimating()
        let group = DispatchGroup()
        group.enter()
        var responseData: String?
        var responseUrl: URL?
        requestHandler(request) { dat, response, error in
            guard error == nil, let data = dat, let url = response?.url else {
                print("Error while making submit button request: \(error), \(dat), \(response)")
                group.leave()
                return
            }
            responseData = String(data: data, encoding: .utf8)
            responseUrl = url
            group.leave()
        }
        group.notify(queue: .main) {
            self.activityIndicator.stopAnimating()
            guard let data = responseData, let url = responseUrl else {
                return
            }
            let vc = WebViewController(htmlString: data, url: url)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func submitButtonSelected(metadata: Dictionary<String, Any>, text: String) {
        guard
            let formData = metadata["formData"] as? String,
            let urlString = metadata["formAction"] as? String,
            let url = URL(string: urlString),
            var request = postRequestUsing(url: url, param: formData)
            else {
                return
        }
        self.viewModel.send(message: text, metadata: nil)
        if let type = metadata["requestType"] as? String, type == "json" {
            let contentType = "application/json"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            requestHandler(request) { _, _, _ in }
        } else {
            let contentType = "application/x-www-form-urlencoded"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            submitButtonResponse(request: request)
        }
    }

    private func shareContact() {
        CNContactStore().requestAccess(for: .contacts) { (granted, _) in
            if granted {
                let vc = CNContactPickerViewController()
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            } else {
                ALUtilityClass.permissionPopUp(withMessage: "Enable Contact permission", andViewController: self)
            }
        }
    }

    func setRichMessageKitTheme() {
        ImageBubbleTheme.sentMessage.bubble.color = ALKMessageStyle.sentBubble.color
        ImageBubbleTheme.sentMessage.bubble.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        ImageBubbleTheme.receivedMessage.bubble.color = ALKMessageStyle.receivedBubble.color
        ImageBubbleTheme.receivedMessage.bubble.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius

        MessageTheme.sentMessage.message = ALKMessageStyle.sentMessage
        MessageTheme.sentMessage.bubble.color = ALKMessageStyle.sentBubble.color
        MessageTheme.sentMessage.bubble.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        MessageTheme.receivedMessage.message = ALKMessageStyle.receivedMessage
        MessageTheme.receivedMessage.bubble.color = ALKMessageStyle.receivedBubble.color
        MessageTheme.receivedMessage.bubble.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius

        MessageTheme.receivedMessage.displayName = ALKMessageStyle.displayName
        MessageTheme.receivedMessage.time = ALKMessageStyle.time
        MessageTheme.sentMessage.time = ALKMessageStyle.time
    }
}

extension ALKConversationViewController: CNContactPickerDelegate {
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        viewModel.send(contact: contact, metadata: configuration.messageMetadata)
        /// Send contact using path viewModelsend(photo:
    }
}

extension ALKConversationViewController: ALKConversationViewModelDelegate {

    public func loadingStarted() {
        activityIndicator.startAnimating()
    }

    public func loadingFinished(error: Error?, targetFocusItemIndex:Int, isLoadNextPage:Bool) {
        activityIndicator.stopAnimating()
        let oldSectionCount = tableView.numberOfSections
        tableView.reloadData()
        if isLoadNextPage == false {
            let newSectionCount = self.viewModel.numberOfSections()
            if newSectionCount > oldSectionCount {
                let offset = newSectionCount - oldSectionCount - 1
                if offset >= 0 && offset < newSectionCount {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadingFinished - scroll to offset:\(offset), total section:\(newSectionCount)")
                    tableView.scrollToRow(at: IndexPath(row: 0, section: offset), at: .none, animated: false)
                }
            }
        }
        print("loading finished")
        DispatchQueue.main.async {
            if self.viewModel.isFirstTime {
                if targetFocusItemIndex != -1 {
                    let _newSectionCount = self.viewModel.numberOfSections()
                    if targetFocusItemIndex < _newSectionCount {
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadingFinished - scroll to targetFocusItemIndex:\(targetFocusItemIndex), total section:\(_newSectionCount)")
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: targetFocusItemIndex) , at: .bottom, animated: false)
                    }else{
                        let _sectionIndex = _newSectionCount - 1
                        if _sectionIndex >= 0 {
                            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadingFinished - scroll to _sectionIndex:\(_sectionIndex), total section:\(_newSectionCount)")
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: _sectionIndex) , at: .bottom, animated: false)
                        }
                    }
                }else{
                    self.tableView.scrollToBottom(animated: false)
                }
                self.saveLastReadMessageIfNeeded()
                self.viewModel.isFirstTime = false
            }
        }
        //show / off scroll down button
        if self.viewModel.messageModels.count > 0 {
            let _lastItemIndex = self.viewModel.messageModels.count-1
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadingFinished - rectForRow _lastItemIndex:\(_lastItemIndex), total section:\(self.viewModel.messageModels.count)")
            let _cellPos = self.tableView.rectForRow(at: IndexPath(row: 0, section: _lastItemIndex))
            if (tableView.isCellVisible(section: _lastItemIndex, row: 0) &&
                _cellPos.maxY <= self.tableView.contentOffset.y + self.tableView.bounds.size.height + 10) ||
                (targetFocusItemIndex == -1 && isLoadNextPage == false){
                self.unreadScrollButton.isHidden = true
            }else {
                self.unreadScrollButton.isHidden = false
            }
        }else{
            self.unreadScrollButton.isHidden = true
        }
        self.hiddenUnReadMessageRemindIndicatorViewIfNeeded()
        
        guard !viewModel.isOpenGroup else {return}
        viewModel.markConversationRead()
    }

    public func messageUpdated() {
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
        }
        tableView.reloadData()
        
        if tableView.isCellVisible(section: self.viewModel.messageModels.count-1, row: 0) {
            self.unreadScrollButton.isHidden = true
        }else if self.isFirstTime == false {
            self.unreadScrollButton.isHidden = false
        }
        self.hiddenUnReadMessageRemindIndicatorViewIfNeeded()
        
        //save for unread message
        self.saveLastReadMessageIfNeeded()
    }

    public func updateMessageAt(indexPath: IndexPath, needReloadTable:Bool) {
        DispatchQueue.main.async {
            if needReloadTable == false {
                self.tableView.beginUpdates()
                self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
                self.tableView.endUpdates()
            }else{
                self.tableView.reloadData()
            }
            //save for unread message
            self.saveLastReadMessageIfNeeded()
        }
    }

    public func removeMessagesAt(indexPath: IndexPath, closureBlock: () -> Void) {
        closureBlock()
        self.tableView.reloadData()
    }
    
    //This is a temporary workaround for the issue that messages are not scrolling to bottom when opened from notification
    //This issue is happening because table view has different cells of different heights so it cannot go to the bottom of cell when using function scrollToBottom
    //And thats why when we check whether last cell is visible or not, it gives false result since the last cell is sometimes not fully visible.
    //This is a known apple bug and has a thread in stackoverflow: https://stackoverflow.com/questions/25686490/ios-8-auto-cell-height-cant-scroll-to-last-row
    private func moveTableViewToBottom(indexPath: IndexPath) {
        guard indexPath.section >= 0 else {
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - moveTableViewToBottom - scroll to indexPath:\(indexPath.section), total section:\(tableView.numberOfSections)")
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let sectionCount = self.tableView.numberOfSections
            if indexPath.section <= sectionCount {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - moveTableViewToBottom - scroll to asyncAfter indexPath:\(indexPath.section), total section:\(self.tableView.numberOfSections)")
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }

    func updateTableView() {
        let oldCount = tableView.numberOfSections
        let newCount = viewModel.numberOfSections()
        guard newCount >= oldCount else {
            self.tableView.reloadData()
            print("😱Tableview shouldn't have more number of sections than viewModel😱")
            return
        }
        let indexSet = IndexSet(integersIn: oldCount..<newCount)

        tableView.beginUpdates()
        tableView.insertSections(indexSet, with: .automatic)
        tableView.endUpdates()
    }

    @objc open func newMessagesAdded() {
        updateTableView()
        //save for unread message as last message
        self.saveLastReadMessageAsLastMessge()
        //Check if current user is removed from the group
        isChannelLeft()

        if isViewLoadedFromTappingOnNotification {
            let indexPath: IndexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
            moveTableViewToBottom(indexPath: indexPath)
            isViewLoadedFromTappingOnNotification = false
        } else {
            if tableView.isCellVisible(section: viewModel.messageModels.count-2, row: 0) { //1 for recent added msg and 1 because it starts with 0
                let indexPath: IndexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
                moveTableViewToBottom(indexPath: indexPath)
            } else if viewModel.messageModels.count > 1 { // Check if the function is called before message is added. It happens when user is added in the group.
                unreadScrollButton.isHidden = false
                self.hiddenUnReadMessageRemindIndicatorViewIfNeeded()
            }
        }
        guard self.isViewLoaded && self.view.window != nil && !viewModel.isOpenGroup else {
            return
        }
        viewModel.markConversationRead()
    }

    public func messageSent(at indexPath: IndexPath) {
        NSLog("current indexpath: %i and tableview section %i", indexPath.section, self.tableView.numberOfSections)
        guard indexPath.section >= self.tableView.numberOfSections else {
            NSLog("rejected indexpath: %i and tableview and section %i", indexPath.section, self.tableView.numberOfSections)
            return
        }
        tableView.beginUpdates()
        tableView.insertSections(IndexSet(integer: indexPath.section), with: .automatic)
        tableView.endUpdates()
        moveTableViewToBottom(indexPath: indexPath)
    }

    public func messageCanSent(at indexPath: IndexPath) {
        if let _messageModel = self.viewModel.messageForRow(indexPath: indexPath) {
            var _messageReplyId:String = ""
            if let msgMetadata = _messageModel.metadata,
                let replyID = msgMetadata[AL_MESSAGE_REPLY_KEY] as? String {
                _messageReplyId = replyID
            }
            let _messageTypeStr = ALKConfiguration.ConversationMessageTypeForApp.getMessageTypeString(type: _messageModel.messageType)
            self.delegateConversationChatContentAction?.didMessageSent(type: _messageTypeStr, messageID:_messageModel.identifier, messageReplyID:_messageReplyId, message: _messageModel.message)
        }
    }
    
    public func updateDisplay(contact: ALContact?, channel: ALChannel?) {
        let profile = viewModel.conversationProfileFrom(contact: contact, channel: channel)
        navigationBar.updateView(profile: profile)
    }

    func rightNavbarButton() -> UIBarButtonItem? {
        guard !configuration.hideRightNavBarButtonForConversationView else {
            return nil
        }
        var button: UIBarButtonItem

        let notificationSelector = #selector(ALKConversationViewController.sendRightNavBarButtonSelectionNotification(_:))
        let notificationCustomSelector = #selector(ALKConversationViewController.sendRightNavBarButtonCustomSelectionNotification(_:))

        if let imageCustom = configuration.conversationViewCustomRightNavBarView {
            button = UIBarButtonItem(
                image: imageCustom,
                style: UIBarButtonItem.Style.plain,
                target: self,
                action: notificationCustomSelector)
        }else if let image = configuration.rightNavBarImageForConversationView {
            button = UIBarButtonItem(
                image: image,
                style: UIBarButtonItem.Style.plain,
                target: self,
                action: notificationSelector)
        } else {
            var selector = notificationSelector
            if configuration.rightNavBarSystemIconForConversationView == .refresh {
                selector = #selector(ALKConversationViewController.refreshButtonAction(_:))
            }

            button = UIBarButtonItem(
                barButtonSystemItem: configuration.rightNavBarSystemIconForConversationView,
                target: self,
                action: selector)
        }
        return button
    }

    func addRefreshButton() {
        self.navigationItem.rightBarButtonItem = rightNavbarButton()
    }

    @objc func refreshButtonAction(_ selector: UIBarButtonItem) {
        viewModel.refresh()
    }

    @objc func sendRightNavBarButtonSelectionNotification(_ selector: UIBarButtonItem) {
        let channelId = (viewModel.channelKey != nil) ? String(describing: viewModel.channelKey!) : ""
        let contactId = viewModel.contactId ?? ""
        let info: [String: Any] = ["ChannelId": channelId, "ContactId": contactId, "ConversationVC": self]

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RightNavBarConversationViewAction"), object: info)
    }

    public func willSendMessage() {
        // Clear reply message and the view
        viewModel.clearSelectedMessageToReply()
        hideReplyMessageView()
    }

    public func updateTyingStatus(status: Bool, userId: String) {
        self.showTypingLabel(status: status, userId: userId)
    }

    public func isPassMessageContentChecking() -> Bool {
       return self.delegateConversationChatContentAction?.isAdminUser() ?? false
    }
}

extension ALKConversationViewController: ALKCreateGroupChatAddFriendProtocol {

    func createGroupGetFriendInGroupList(friendsSelected: [ALKFriendViewModel], groupName: String, groupImgUrl: String, friendsAdded: [ALKFriendViewModel]) {
        if viewModel.isGroup {
            viewModel.updateGroup(groupName: groupName, groupImage: groupImgUrl, friendsAdded: friendsAdded)
            _ = navigationController?.popToViewController(self, animated: true)
        }
    }
}

extension ALKConversationViewController: ALKShareLocationViewControllerDelegate {
    func locationDidSelected(geocode: Geocode, image: UIImage) {
        let (message, indexPath) = viewModel.add(geocode: geocode,metadata: self.configuration.messageMetadata)
        guard let newMessage = message, let newIndexPath = indexPath else {
            return
        }
        self.tableView.beginUpdates()
        self.tableView.insertSections(IndexSet(integer: (newIndexPath.section)), with: .automatic)
        self.tableView.endUpdates()

        // Not scrolling down without the delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.scrollToBottom(animated: false)
        }
        viewModel.sendGeocode(message: newMessage, indexPath: newIndexPath)
    }
}

extension ALKConversationViewController: ALKLocationCellDelegate {
    func displayLocation(location: ALKLocationPreviewViewModel) {
        let latLonString = String(format: "%f,%f", location.coordinate.latitude, location.coordinate.longitude)
        let locationString = String(format: "https://maps.google.com/maps?q=loc:%@", latLonString)
        guard let locationUrl = URL(string: locationString) else { return }
        UIApplication.shared.openURL(locationUrl)

    }
}

extension ALKConversationViewController: ALKAudioPlayerProtocol, ALKVoiceCellProtocol {

    func reloadVoiceCell() {
        for cell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell) else {return}
            if let message = viewModel.messageForRow(indexPath: indexPath) {
                if message.messageType == .voice && message.identifier == audioPlayer.getCurrentAudioTrack() {
                    print("voice cell reloaded with row: ", indexPath.row, indexPath.section)
                    tableView.reloadSections([indexPath.section], with: .none)
                    break
                }
            }
        }
    }

    //MAKR: Voice and Audio Delegate
    func playAudioPress(identifier: String) {
        DispatchQueue.main.async { [weak self] in
            NSLog("play audio pressed")
            guard let weakSelf = self else { return }

            //if we have previously play audio, stop it first
            if !weakSelf.audioPlayer.getCurrentAudioTrack().isEmpty && weakSelf.audioPlayer.getCurrentAudioTrack() != identifier {
                //pause
                NSLog("already playing, change it to pause")
                guard var lastMessage =  weakSelf.viewModel.messageForRow(identifier: weakSelf.audioPlayer.getCurrentAudioTrack()) else {return}

                if Int(lastMessage.voiceCurrentDuration) > 0 {
                    lastMessage.voiceCurrentState = .pause
                    lastMessage.voiceCurrentDuration = weakSelf.audioPlayer.secLeft
                } else {
                    let lastMessageCopy = lastMessage
                    lastMessage.voiceCurrentDuration = lastMessageCopy.voiceTotalDuration
                    lastMessage.voiceCurrentState = .stop
                }
                weakSelf.audioPlayer.pauseAudio()
            }
            NSLog("now it will be played")
            //now play
            guard
                var currentVoice =  weakSelf.viewModel.messageForRow(identifier: identifier),
                let section = weakSelf.viewModel.sectionFor(identifier: identifier)
            else { return }
            if currentVoice.voiceCurrentState == .playing {
                currentVoice.voiceCurrentState = .pause
                currentVoice.voiceCurrentDuration = weakSelf.audioPlayer.secLeft
                weakSelf.audioPlayer.pauseAudio()
                weakSelf.tableView.reloadSections([section], with: .none)
            } else {
                NSLog("reset time to total duration")
                //reset time to total duration
                if currentVoice.voiceCurrentState  == .stop || currentVoice.voiceCurrentDuration < 1 {
                    let currentVoiceCopy = currentVoice
                    currentVoice.voiceCurrentDuration = currentVoiceCopy.voiceTotalDuration
                }

                if let data = currentVoice.voiceData {
                    let voice = data as NSData
                    //start playing
                    NSLog("Start playing")
                    weakSelf.audioPlayer.setAudioFile(data: voice, delegate: weakSelf, playFrom: currentVoice.voiceCurrentDuration,lastPlayTrack:currentVoice.identifier)
                    currentVoice.voiceCurrentState = .playing
                    weakSelf.tableView.reloadSections([section], with: .none)
                }
            }
        }

    }

    func audioPlaying(maxDuratation: CGFloat, atSec: CGFloat,lastPlayTrack:String) {

        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            guard var currentVoice =  weakSelf.viewModel.messageForRow(identifier: lastPlayTrack) else {return}
            if currentVoice.messageType == .voice {

                if currentVoice.identifier == lastPlayTrack {
                    if atSec <= 0 {
                        currentVoice.voiceCurrentState = .stop
                        currentVoice.voiceCurrentDuration = 0
                    } else {
                        currentVoice.voiceCurrentState = .playing
                        currentVoice.voiceCurrentDuration = atSec
                    }
                }
                print("audio playing id: ", currentVoice.identifier)
                weakSelf.reloadVoiceCell()
            }
        }
    }

    func audioStop(maxDuratation: CGFloat,lastPlayTrack:String) {

        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }

            guard var currentVoice =  weakSelf.viewModel.messageForRow(identifier: lastPlayTrack) else {return}
            if currentVoice.messageType == .voice {
                if currentVoice.identifier == lastPlayTrack {
                    currentVoice.voiceCurrentState = .stop
                    currentVoice.voiceCurrentDuration = 0.0
                }
            }
            guard let section = weakSelf.viewModel.sectionFor(identifier: lastPlayTrack) else { return }
            weakSelf.tableView.reloadSections([section], with: .none)
        }
    }

    func audioPause(maxDuration: CGFloat, atSec: CGFloat, identifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard
                let weakSelf = self,
                var currentVoice =  weakSelf.viewModel.messageForRow(identifier: identifier),
                currentVoice.messageType == .voice,
                let section = weakSelf.viewModel.sectionFor(identifier: identifier)
            else { return }
            currentVoice.voiceCurrentState = .pause
            currentVoice.voiceCurrentDuration = atSec
            weakSelf.tableView.reloadSections([section], with: .none)
        }
    }

    func stopAudioPlayer() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            if var lastMessage = weakSelf.viewModel.messageForRow(identifier: weakSelf.audioPlayer.getCurrentAudioTrack()) {

                if lastMessage.voiceCurrentState == .playing {
                    weakSelf.audioPlayer.pauseAudio()
                    lastMessage.voiceCurrentState = .pause
                    weakSelf.reloadVoiceCell()
                }
            }
        }
    }
}

extension ALKConversationViewController: ALMQTTConversationDelegate {

    public func mqttDidConnected() {
        if individualLaunch {
            subscribeChannelToMqtt()
        }
        //auto refresh after
        if self.isAutoRefreshMessage {
            self.isAutoRefreshMessage = false
            self.viewModel.refresh()
        }
    }

    public func syncCall(_ alMessage: ALMessage!, andMessageList messageArray: NSMutableArray!) {
        print("sync call1 ", messageArray)
        guard let message = alMessage else { return }
        sync(message: message)
    }

    public func delivered(_ messageKey: String!, contactId: String!, withStatus status: Int32) {
        updateDeliveryReport(messageKey: messageKey, contactId: contactId, status: status)
    }

    public func updateStatus(forContact contactId: String!, withStatus status: Int32) {
        updateStatusReport(contactId: contactId, status: status)
    }

    public func updateTypingStatus(_ applicationKey: String!, userId: String!, status: Bool) {
        print("Typing status is", status)
        guard viewModel.contactId == userId || viewModel.channelKey != nil else {
            return
        }
        print("Contact id matched")
        showTypingLabel(status: status, userId: userId)

    }

    public func updateLastSeen(atStatus alUserDetail: ALUserDetail!) {
        print("Last seen updated")
        guard let contact = contactService.loadContact(byKey: "userId", value: alUserDetail.userId) else {
            return
        }
        guard contact.userId == viewModel.contactId, !viewModel.isGroup else { return }
        navigationBar.updateStatus(isOnline: contact.connected, lastSeenAt: contact.lastSeenAt)
    }

    public func mqttConnectionClosed() {
        if viewModel.isOpenGroup &&  mqttRetryCount < maxMqttRetryCount {
            subscribeChannelToMqtt()
        }
        NSLog("MQTT connection closed")
    }

    public func reloadData(forUserBlockNotification userId: String!, andBlockFlag flag: Bool) {
        print("reload data")
        checkUserBlock()
    }

    public func updateUserDetail(_ userId: String!) {
        guard let userId = userId else { return }
        print("update user detail")
        viewModel.updateUserDetail(userId)
    }
}

extension ALKConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // Video attachment
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == "public.movie" {
            guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
            print("video path is: ", url.path)
            viewModel.encodeVideo(videoURL: url, completion: {
                path in
                guard let newPath = path else { return }
                var indexPath: IndexPath?
                DispatchQueue.main.async {
                    (_, indexPath) = self.viewModel.sendVideo(atPath: newPath, sourceType: picker.sourceType,metadata: self.configuration.messageMetadata)
                    self.tableView.beginUpdates()
                    self.tableView.insertSections(IndexSet(integer: (indexPath?.section)!), with: .automatic)
                    self.tableView.endUpdates()
                    self.tableView.scrollToBottom(animated: false)
                    guard let newIndexPath = indexPath, let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyVideoCell else { return }
                    guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                        let notificationView = ALNotificationView()
                        notificationView.noDataConnectionNotificationView()
                        return
                    }
                    self.viewModel.uploadVideo(view: cell, indexPath: newIndexPath)
                }
            })
        }

        picker.dismiss(animated: true, completion: nil)
    }
}

extension ALKConversationViewController: ALKCustomPickerDelegate {
    func filesSelected(images: [UIImage], videos: [String]) {
        self.sendMessageWithHandleUnreadModel {
            let fileCount = images.count + videos.count
            for index in 0..<fileCount {
                if index < images.count {
                    let image = images[index]
                    let (message, indexPath) = self.viewModel.send(
                        photo: image,
                        metadata: self.configuration.messageMetadata)
                    guard message != nil, let newIndexPath = indexPath else { return }
                    //            DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
                    self.tableView.endUpdates()
                    self.tableView.scrollToBottom(animated: false)
                    //            }
                    guard let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyPhotoPortalCell else { return }
                    guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                        let notificationView = ALNotificationView()
                        notificationView.noDataConnectionNotificationView()
                        return
                    }
                    self.viewModel.uploadImage(view: cell, indexPath: newIndexPath)
                } else {
                    let path = videos[index - images.count]
                    guard let indexPath = self.viewModel.sendVideo(
                        atPath: path,
                        sourceType: .photoLibrary,
                        metadata : self.configuration.messageMetadata).1
                        else { continue }
                    self.tableView.beginUpdates()
                    self.tableView.insertSections(IndexSet(integer: indexPath.section), with: .automatic)
                    self.tableView.endUpdates()
                    self.tableView.scrollToBottom(animated: false)
                    guard let cell = self.tableView.cellForRow(at: indexPath) as? ALKMyVideoCell else { return }
                    guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                        let notificationView = ALNotificationView()
                        notificationView.noDataConnectionNotificationView()
                        return
                    }
                    self.viewModel.uploadVideo(view: cell, indexPath: indexPath)
                }
                
            }
        }
        
    }
}

extension ALKConversationViewController: NavigationBarCallbacks {
    func backButtonTapped() {
        backTapped()
    }

    func titleTapped() {
        hideMoreBar()
        view.endEditing(true)
        self.chatBar.resignAllResponderFromTextView()
        //for custom show detail view
        if self.configuration.enableCustomeGroupDetail {
            guard isGroupDetailActionEnabled else { return }
            self.delegateConversationChatContentAction?.groupTitleViewClicked(chatView: self)
            return
        }
        
        if let contact = contactDetails(), let contactId = contact.userId {
            let info: [String: Any] =
                ["Id": contactId,
                 "Name": contact.getDisplayName() ?? "",
                 "Controller": self]

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserProfileSelected"), object: info)
        }
        guard isGroupDetailActionEnabled else { return }
        showParticipantListChat()
    }
    
    func getTitle() -> String? {
        return self.delegateConversationChatContentAction?.getGroupTitle(chatView: self)
    }

    private func contactDetails() -> ALContact? {
        guard viewModel != nil else { return nil }
        guard
            viewModel.channelKey == nil,
            viewModel.conversationProxy == nil,
            let contactId = viewModel.contactId else {
                return nil
        }
        return ALContactService().loadContact(byKey: "userId", value: contactId)
    }

}

extension ALKConversationViewController: AttachmentDelegate {
    func tapAction(message: ALKMessageViewModel) {
        //before show need paid
        let _isAllowOpen = self.isEnablePaidFeature()
        if _isAllowOpen == false {
            self.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.funcNeedPaid)
            return
        }
        let storyboard = UIStoryboard.name(
            storyboard: UIStoryboard.Storyboard.mediaViewer,
            bundle: Bundle.applozic)
        guard let nav = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
        let vc = nav.viewControllers.first as? ALKMediaViewerViewController

        let messageModels = viewModel.messageModels.filter {
            ($0.messageType == .photo || $0.messageType == .video) && ($0.downloadPath() != nil) && ($0.downloadPath()!.1 != nil)
        }

        guard let msg = message as? ALKMessageModel,
            let currentIndex = messageModels.index(of: msg) else { return }
        vc?.viewModel = ALKMediaViewerViewModel(
            messages: messageModels,
            currentIndex: currentIndex,
            localizedStringFileName: localizedStringFileName)
        self.present(nav, animated: true, completion: nil)
    }
}

//MARK: - stockviva
extension ALKConversationViewController {
    
    //menu button clicked
    @objc func sendRightNavBarButtonCustomSelectionNotification(_ selector: UIBarButtonItem) {
        hideMoreBar()
        view.endEditing(true)
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatContentAction?.rightMenuClicked(chatView: self)
    }
    
    //navigationBar control
    public func hiddenGroupMuteButton(_ hidden:Bool){
        self.navigationBar.groupMuteImage.isHidden = hidden
    }
    
    public func enableJoinGroupButton(_ isEnable:Bool, isEndEditing:Bool = true){
        //tag: on / off join group button
        hideMoreBar()
        if isEndEditing {
            view.endEditing(true)
            self.chatBar.resignAllResponderFromTextView()
        }
        if isEnable, let _btnInfo = self.delegateConversationChatContentAction?.getJoinGroupButtonInfo(chatView: self) {
            self.enableShowJoinGroupMode = true
            self.chatBar.showJoinGroupButton(title: _btnInfo.title, backgroundColor: _btnInfo.backgroundColor, textColor: _btnInfo.textColor, rightIcon: _btnInfo.rightIcon)
        }else{
            self.enableShowJoinGroupMode = false
            self.chatBar.hiddenJoinGroupButton()
        }
    }
    
    public func enableBlockChatButton(_ isEnable:Bool, isEndEditing:Bool = true){
        //tag: on / off join group button
        hideMoreBar()
        self.enableShowBlockChatMode = isEnable
        if isEndEditing {
            view.endEditing(true)
            self.chatBar.resignAllResponderFromTextView()
        }
        self.chatBar.hiddenBlockChatButton(!self.enableShowBlockChatMode)
    }
    
    public func showPinMessageView(isHidden:Bool, pinMsgUuid:String? = nil, userName:String? = nil, userIconUrl:String? = nil, viewModel: ALKMessageViewModel? = nil){
        if let _viewModel = viewModel, isHidden == false {
            self.pinMessageView.isHidden = isHidden
            let height: CGFloat = isHidden ? 0 : Padding.PinMessageView.height
            self.pinMessageView.constraint(withIdentifier: ConstraintIdentifier.pinMessageView)?.constant = height
            self.pinMessageView.updateContent(pinMsgUuid:pinMsgUuid, userName: userName, userIconUrl: userIconUrl, viewModel: _viewModel)
        }else{
            self.pinMessageView.isHidden = true
            let height: CGFloat = 0
            self.pinMessageView.constraint(withIdentifier: ConstraintIdentifier.pinMessageView)?.constant = height
        }
    }
    
    private func prepareDiscrimationView() {
        self.discrimationView.addTarget(self, action: #selector(discrimationToucUpInside(_:)), for: .touchUpInside)
        if let _discInfo = self.delegateConversationChatContentAction?.isShowDiscrimation(chatView: self), _discInfo.isShow {
            self.discrimationView.isHidden = false
            self.discrimationViewHeightConstraint?.constant = 20
            self.discrimationView.setTitle(_discInfo.title, for: .normal)
        }else{
            self.discrimationView.isHidden = true
            self.discrimationViewHeightConstraint?.constant = 0
            self.discrimationView.setTitle("", for: .normal)
        }
    }
    
    private func presentMessageDetail(isPinMsg:Bool = false, userName:String?, userIconUrl:String?, viewModel: ALKMessageViewModel){
        let _storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.svMessageDetailView, bundle: Bundle.applozic)
        var _presentVC:ALKSVBaseMessageDetailViewController?
        let _msgType = isPinMsg ? viewModel.getContentTypeForPinMessage() : viewModel.messageType
        if _msgType == .text {
            if let _vc = _storyboard.instantiateViewController(withIdentifier: "ALKSVMessageDetailViewController") as? ALKSVMessageDetailViewController {
                _vc.messageViewLinkClicked = { (url) in
                    if self.configuration.enableOpenLinkInApp {
                        self.delegateConversationChatContentAction?.openLink(url: url, sourceView: _vc, isPushFromSourceView:true)
                    }
                }
                _presentVC = _vc
            }
        }else if _msgType == .photo {
            if let _vc = _storyboard.instantiateViewController(withIdentifier: "ALKSVImageMessageDetailViewController") as? ALKSVImageMessageDetailViewController {
                _vc.downloadTapped = {[weak self] value in
                    self?.viewModel.downloadAttachment(message: viewModel, viewController: _vc)
                }
                _presentVC = _vc
            }
        }else if _msgType == .document {
            if let _vc = _storyboard.instantiateViewController(withIdentifier: "ALKSVDocumentMessageDetailViewController") as? ALKSVDocumentMessageDetailViewController {
                _vc.downloadTapped = {[weak self] value in
                    self?.viewModel.downloadAttachment(message: viewModel, viewController: _vc)
                }
                _presentVC = _vc
            }
        }
        
        if let _pVC = _presentVC {
            _pVC.configuration = self.configuration
            _pVC.isViewFromPinMessage = isPinMsg
            _pVC.userName = userName
            _pVC.userIconUrl = userIconUrl
            _pVC.viewModel = viewModel
            _pVC.delegate = self
            _pVC.modalPresentationStyle = .overCurrentContext
            _pVC.modalTransitionStyle = .crossDissolve
            self.present(_pVC, animated: true, completion: nil)
        }
    }
    
    func didReplyClickedInCell(replyMessage: ALKMessageViewModel){
        var _userDisplayName:String? = nil
        var _userIconUrl:String? = nil
        if replyMessage.isMyMessage {
            _userDisplayName = ALUserDefaultsHandler.getDisplayName()
            _userIconUrl = ALUserDefaultsHandler.getProfileImageLinkFromServer()
            if _userDisplayName == nil {
                _userDisplayName = ""
            }
            if _userIconUrl == nil {
                _userIconUrl = ""
            }
        }
        self.presentMessageDetail(userName: _userDisplayName, userIconUrl: _userIconUrl, viewModel: replyMessage)
    }
    
    func sendMessageWithHandleUnreadModel(completedBlock:@escaping ()->Void){
        //check model
        if self.viewModel.isUnreadMessageMode {
            self.viewModel.messageSendUnderUnreadModel(startProcess: {
                self.scrollingState = .idle
                self.lastScrollingPoint = CGPoint.zero
                self.loadingStarted()
            }) {//completed
                if self.activityIndicator.isAnimating == true {
                    self.activityIndicator.stopAnimating()
                }
                completedBlock()
            }
        }else{
            completedBlock()
        }
    }
}

//MARK: - stockviva (ALKSVPinMessageViewDelegate)
extension ALKConversationViewController: ALKSVPinMessageViewDelegate {
    func didPinMessageClicked(userName:String?, userIconUrl:String?, viewModel: ALKMessageViewModel) {
        self.delegateConversationChatContentAction?.didPinMessageClicked()
        if self.isEnablePaidFeature() == false {
            self.requestToShowAlert(type: .funcNeedPaidForPinMsg)
            return
        }
        //show message
        self.presentMessageDetail(isPinMsg:true, userName:userName, userIconUrl:userIconUrl, viewModel: viewModel)
    }
    
    func closeButtonClicked(pinMsgUuid:String?, viewModel: ALKMessageViewModel) {
        self.delegateConversationChatContentAction?.didPinMessageCloseButtonClicked(pinMsgUuid:pinMsgUuid)
    }
}

//MARK: - stockviva (ALKSVMessageDetailViewControllerDelegate)
extension ALKConversationViewController: ALKSVMessageDetailViewControllerDelegate {
    func didUserIconClicked(sender:UIViewController, viewModel:ALKMessageViewModel) {
         self.delegateConversationChatContentAction?.didUserProfileIconClicked(sender:sender, viewModel:viewModel)
    }
    
    func didMessageShow(sender:UIViewController, viewModel:ALKMessageViewModel, isFromPinMessage:Bool) {
        if isFromPinMessage {
            self.delegateConversationChatContentAction?.didPinMessageShow(sender: sender, viewModel: viewModel)
        }
    }
}

//MARK: - stockviva (UIDocumentPickerDelegate)
extension ALKConversationViewController: UIDocumentPickerDelegate, ALKFileUploadConfirmViewControllerDelegate {
    //UIDocumentPickerDelegate
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.showDocumentConfirmPage(urls: [url])
    }
    
    @available(iOS 11.0, *)
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.showDocumentConfirmPage(urls: urls)
    }
    
    //ALKFileUploadConfirmViewControllerDelegate
    private func showDocumentConfirmPage(urls: [URL]){
        //check and block over file size limit
        for  url in urls {
            let _fileSize = ALKFileUtils().getFileSizeWithMB(url: url)
            if _fileSize > self.configuration.maxUploadFileMBSize {
                self.requestToShowAlert(type:.attachmentFileSizeOverLimit)
                return
            }
        }
        let _vc:ALKFileUploadConfirmViewController = ALKFileUploadConfirmViewController(configuration:self.configuration)
        _vc.urlList.append(contentsOf: urls)
        _vc.delegate = self
        self.navigationController?.pushViewController(_vc, animated: true)
    }
    
    public func didStartUploadFiles(urls:[URL]){
        self.sendMessageWithHandleUnreadModel {
            //loop to upload file
            for  url in urls {
                let (message, indexPath) = self.viewModel.send(fileURL: url, metadata: self.configuration.messageMetadata)
                guard message != nil, let newIndexPath = indexPath else { return }
                //        DispatchQueue.main.async {
                self.tableView.beginUpdates()
                self.tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
                self.tableView.endUpdates()
                self.tableView.scrollToBottom(animated: false)
                //        }
                guard let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyDocumentCell else { return }
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                self.viewModel.uploadFile(view: cell, indexPath: newIndexPath)
            }
        }
    }
}

//MARK: - stockviva (ConversationChatBarActionDelegate)
extension ALKConversationViewController: ChatBarRequestActionDelegate{
    public func chatBarRequestGetTextViewPashHolder(chatBar: ALKChatBar) -> String? {
        return self.delegateConversationChatBarAction?.getTextViewPashHolder(chatBar: chatBar)
    }
    
    public func chatBarRequestIsHiddenJoinGroupButton(chatBar:ALKChatBar, isHidden:Bool) {
        self.delegateConversationChatBarAction?.isHiddenJoinGroupButton(chatBar: chatBar, isHidden:isHidden)
    }
    
    public func chatBarRequestIsHiddenBlockChatButton(chatBar:ALKChatBar, isHidden:Bool) {
        self.delegateConversationChatBarAction?.isHiddenBlockChatButton(chatBar: chatBar, isHidden:isHidden)
    }
    
    public func chatBarRequestJoinGroupButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?) {
        hideMoreBar()
        view.endEditing(true)
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatBarAction?.joinGroupButtonClicked(chatBar: chatBar, chatView:self)
    }
    
    public func chatBarRequestBlockChatButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?) {
        hideMoreBar()
        view.endEditing(true)
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatBarAction?.blockChatButtonClicked(chatBar: chatBar, chatView:self)
    }
}

//MARK: - stockviva (ConversationCellRequestInfoDelegate)
extension ALKConversationViewController: ConversationCellRequestInfoDelegate{
    public func isEnableReplyMenuItem() -> Bool {
        return self.enableShowJoinGroupMode == false && self.enableShowBlockChatMode == false
    }
    
    public func isEnablePaidFeature() -> Bool {
        return self.conversationType == .free || ( self.conversationType == .paid && self.isUserPaid )
    }
    
    public func isEnablePinMsgMenuItem() -> Bool {
        return self.delegateConversationChatContentAction?.isAdminUser() ?? false
    }
    
    public func requestToShowAlert(type:ALKConfiguration.ConversationErrorType){
        self.delegateConversationChatContentAction?.showAlert(type:type)
    }
    
    public func getSelfUserHashId() -> String? {
        return self.delegateConversationChatContentAction?.getLoginUserHashId()
    }
}

//MARK: - stockviva unread message
extension ALKConversationViewController {
    
    func saveLastReadMessageIfNeeded(){
        if self.isViewDisappear {
            return
        }
        let _maxYForVisableContent = self.tableView.contentOffset.y + self.tableView.bounds.size.height
        for _cellIndex in self.tableView.indexPathsForVisibleRows?.reversed() ?? [] {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - saveLastReadMessageIfNeeded - rectForRow _cellIndex:\(_cellIndex), total section:\(self.tableView.numberOfSections)")
            let _cellPos = self.tableView.rectForRow(at: _cellIndex)
            let _cellMinHeightOffset = _cellPos.height / 2.5
            if (_cellPos.maxY - _cellMinHeightOffset) <= _maxYForVisableContent {
                if let _cellItem =  self.viewModel.messageForRow(indexPath: _cellIndex),
                    let _createDate = _cellItem.createdAtTime,
                    let _chKey = self.viewModel.channelKey,
                    let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey,
                    _cellItem.isSent == true  {
                    debugPrint("PL**** - \(_cellItem.message ?? "nil")")
                    ALKSVUserDefaultsControl.shared.saveLastReadMessageTime(chatGroupId: _chatGroupId, time: _createDate.intValue)
                    break
                }
            }
        }
    }
    
    func saveLastReadMessageAsLastMessge(){
        if self.isViewDisappear {
            return
        }
        if let _cellItem =  self.viewModel.messageModels.last,
            let _createDate = _cellItem.createdAtTime,
            let _chKey = self.viewModel.channelKey,
            let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey,
            _cellItem.isSent == true {
            debugPrint("PL**** - \(_cellItem.message ?? "nil")")
            ALKSVUserDefaultsControl.shared.saveLastReadMessageTime(chatGroupId: _chatGroupId, time: _createDate.intValue)
        }
    }
    
    func hiddenUnReadMessageRemindIndicatorViewIfNeeded(){
        if let _lastUnReadMsgKey = self.viewModel.lastUnreadMessageKey,
            let _arrayVisableIndex = tableView.indexPathsForVisibleRows?.last,
            let _msgModel = self.viewModel.messageForRow(indexPath: _arrayVisableIndex),
            _msgModel.identifier == _lastUnReadMsgKey && self.viewModel.isFirstTime == false {//is scroll to last cell
            self.unReadMessageRemindIndicatorView.isHidden = true
            self.viewModel.clearUnReadMessageData(isCancelTheModel:false)
        }else{
            self.unReadMessageRemindIndicatorView.isHidden = self.viewModel.lastUnreadMessageKey == nil || self.unreadScrollButton.isHidden
        }
    }
}

//MARK: - subclass
fileprivate class ALKCVDocumentPickerViewController :UIDocumentPickerViewController{
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(documentTypes allowedUTIs: [String], in mode: UIDocumentPickerMode) {
        super.init(documentTypes: allowedUTIs, in: mode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIButton.appearance().tintColor = UIColor.blue
        UIBarButtonItem.appearance().tintColor = UIColor.blue
        UINavigationBar.appearance().tintColor = UIColor.blue
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.blue]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIButton.appearance().tintColor = UIColor.white
        UIBarButtonItem.appearance().tintColor = .white
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
    }
    
}

