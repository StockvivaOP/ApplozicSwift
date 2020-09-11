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

    public lazy var chatBar = ALKChatBar(frame: CGRect.zero, configuration: self.configuration)
    
    var contactService: ALContactService!

    /// Check if view is loaded from notification
    private var isViewLoadedFromTappingOnNotification: Bool = false

    /// See configuration.
    private var isGroupDetailActionEnabled = true

    /// See configuration.
    private var isProfileTapActionEnabled = true

    var isFirstTime = true
    private var bottomConstraint: NSLayoutConstraint?
    var isJustSent: Bool = false

    //MQTT connection retry
    fileprivate var mqttRetryCount = 0
    fileprivate var maxMqttRetryCount = 3

    fileprivate let audioPlayer = ALKAudioPlayer()

    fileprivate var alMqttConversationService: ALMQTTConversationService!
    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

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
    fileprivate enum MqttConnectStatus: String {
        case none = "none"
        case connecting = "connecting"
        case connected = "connected"
        case disConnected = "disConnected"
    }
    
    fileprivate enum MqttConnectRequestFrom: String {
        case none = "none"
        case appForeground = "appForeground"
        case viewRefresh = "viewRefresh"
        case mqttDisConnected = "mqttDisConnected"
    }
    
    public var navigationBar = SVALKConversationNavBar()
    
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
    
    public var enableBookmarkMsgFeture: Bool = true
    public var enableShowJoinGroupMode: Bool = false
    public var enableShowBlockChatMode: Bool = false
    public var conversationType: ALKConversationType = .free
    public var isUserPaid: Bool = false
    //delegate object
    public var delegateConversationChatBarAction:ConversationChatBarActionDelegate?
    public var delegateConversationChatContentAction:ConversationChatContentActionDelegate?
    public var delegateConversationMessageBoxAction:ConversationMessageBoxActionDelegate?
    public var delegateChatGroupLifeCycle:ConversationChatContentLifeCycleDelegate?
    private var discrimationViewHeightConstraint: NSLayoutConstraint?
    private var isViewFirstLoad: Bool = true
    private var isViewFirstLoadingMessage: Bool = true
    private var isViewDisappear = false
    private var isAppToBackground = false
    private var isLeaveView = false
    fileprivate var mqttConnectStatus:MqttConnectStatus = .none
    fileprivate var mqttConnectRequestFrom:MqttConnectRequestFrom = .none
    var scrollingState:ALKConversationViewScrollingState = .idle
    var lastScrollingPoint:CGPoint = CGPoint.zero
    lazy open var discrimationView: UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor.ALKSVGreyColor245()
        view.setTitleColor(UIColor.ALKSVGreyColor102(), for: .normal)
        view.setFont(font: UIFont.systemFont(ofSize: 8))
        view.titleLabel?.textAlignment = .center
        return view
    }()
    
    lazy public var unReadMessageRemindIndicatorView: UIView = {
        let _view = UIView(frame: CGRect.zero)
        _view.backgroundColor = UIColor.ALKSVStockColorRed()
        _view.layer.cornerRadius = 7.5
        _view.isHidden = true
        return _view
    }()
    
    lazy private var floatingAffiliatePromoButton: UIButton = {
        let view = UIButton(type: UIButton.ButtonType.custom)
        view.backgroundColor = .clear
        view.isHidden = true
        view.addTarget(self, action: #selector(ALKConversationViewController.didFloatingAffiliatePromotionButtonTouchUpInside), for: .touchUpInside)
        return view
    }()
    
    lazy private var floatingShareButton: UIButton = {
        let view = UIButton(type: UIButton.ButtonType.custom)
        view.backgroundColor = .clear
        view.isHidden = true
        view.addTarget(self, action: #selector(ALKConversationViewController.didFloatingShareButtonTouchUpInside(_:)), for: .touchUpInside)
        return view
    }()
    
    lazy private var floatingShareTipButtonArrowImg: UIImageView = {
        let _img = UIImage(named: "sv_temp_style_bubble_arrow", in: Bundle.applozic, compatibleWith: nil)
        let view = UIImageView(image: _img)
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    lazy private var floatingShareTipButton: UIButton = {
        let view = UIButton(type: UIButton.ButtonType.custom)
        view.backgroundColor = .clear
        view.setTitleColor(.white, for: .normal)
        view.setFont(font: UIFont.systemFont(ofSize: 13.0, weight: .semibold))
        view.isHidden = true
        return view
    }()
    
    lazy public var svMarqueeView:SVALKMarqueeView = {
        let view = SVALKMarqueeView(frame: CGRect.zero)
        view.isHidden = true
        return view
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
            
            let _contentSize = tableView.contentSize
            var _newY = tableView.contentOffset.y + keyboardSize.height
            if _newY > _contentSize.height - tableView.bounds.size.height  {
                _newY = _contentSize.height - tableView.bounds.size.height
            }
            tableView.contentOffset = CGPoint(x: tableView.contentOffset.x, y: _newY)
            
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
                })
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "newMessageNotification"), object: nil, queue: nil, using: {
            notification in
            guard self.viewModel != nil && self.isLeaveView == false else { return }
            if let msgArray = notification.object as? [ALMessage] {
                print("new notification received: ", msgArray.first?.message as Any, msgArray.count )
                self.viewModel.checkDidContainSpecialMessage(messages: msgArray)
            }
            guard self.viewModel.isUnreadMessageMode == false && self.viewModel.isFocusReplyMessageMode == false else {
                return
            }
            guard let list = notification.object as? [Any], !list.isEmpty, self.isViewLoaded else { return }
//            weakSelf.handlePushNotification = false
            self.viewModel.addMessagesToList(list, isNeedOnUnreadMessageModel: self.unreadScrollButton.isHidden == false)
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "messageMetaDataUpdateNotification"), object: nil, queue: nil, using: {
            notification in
            guard self.viewModel != nil && self.isLeaveView == false else { return }
            if let _msgObj = notification.object as? ALMessage {
                print("message meta data update notification received: ", _msgObj.message, _msgObj.metadata)
                self.viewModel.updateMessageContent(updatedMessage: _msgObj)
            }else{
                print("message meta data update notification received: nil content")
            }
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil, queue: nil, using: {
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
            guard let key = weakSelf.viewModel.channelKey, let channel = alChannelService.getChannelByKey(key), let _ = channel.name else { return }
            let profile = weakSelf.viewModel.conversationProfileFrom(contact: nil, channel: channel)
            weakSelf.navigationBar.updateContent(profile: profile)
            weakSelf.newMessagesAdded(error: nil, isFromSyncMessage: false, retryHandler: nil)
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND_CV"), object: nil, queue: nil) { [weak self] _ in
            self?.isAppToBackground = false
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
//            let _ = weakSelf.viewModel.currentConversationProfile(completion: { (profile) in
//                guard let profile = profile else { return }
//                weakSelf.navigationBar.updateContent(profile: profile)
//            })
            if self?.isViewFirstLoad == false {
                if self?.viewModel.isUnreadMessageMode == false &&
                    self?.viewModel.isFocusReplyMessageMode == false {
                    self?.viewModel.syncOpenGroupMessage(isNeedOnUnreadMessageModel: true)
                }
                self?.mqttConnectRequestFrom = .appForeground
                self?.subscribeChannelToMqtt()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "APP_ENTER_IN_BACKGROUND_CV"), object: nil, queue: nil) { [weak self] _ in
            self?.isAppToBackground = true
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            if self?.isViewFirstLoad == false {
                self?.unsubscribingChannel()
            }
        }
    }

    override func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isViewDisappear = false
        self.isLeaveView = false
        self.viewModel.isLeaveChatGroup = false
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            tableView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        }
        //refresh nav bar content
        self.navigationBar.updateContent()
        //self.edgesForExtendedLayout = []
        alMqttConversationService = ALMQTTConversationService.sharedInstance()
        alMqttConversationService.mqttConversationDelegate = self
        alMqttConversationService.subscribeToConversation()
        viewModel.delegate = self
        
        if self.isFirstTime {
            setupView()
            self.refreshViewController()
            self.setupNavigation()
        }else{
            self.viewModel.syncOpenGroupMessage(isNeedOnUnreadMessageModel: true)
            configureView()
        }
        self.prepareAllCustomView()
        
        contentOffsetDictionary = Dictionary<NSObject,AnyObject>()
        self.isViewFirstLoad = false
        print("id: ", viewModel.messageModels.first?.contactId as Any)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.isViewFirstLoad = true
        setupConstraints()
        //tag: stockviva
        self.isViewFirstLoadingMessage = true
        self.delegateChatGroupLifeCycle?.didFirstLoadStart()
        self.viewModel.delegateConversationChatContentAction = self.delegateConversationChatContentAction
        self.viewModel.delegateChatGroupLifeCycle = self.delegateChatGroupLifeCycle
        self.tableView.scrollsToTop = false
        self.chatBar.delegate = self
        self.chatBar.setUpViewConfig()
        //tag: on / off join group button
        self.enableJoinGroupButton(self.enableShowJoinGroupMode)
        self.enableBlockChatButton(self.enableShowBlockChatMode)
        self.showPinMessageBarView(isHidden: true)
        self.hideReplyMessageView()
        //set marquee view
        self.svMarqueeView.delegate = self
        //add loading
        activityIndicator.color = UIColor.white
        activityIndicator.backgroundColor = UIColor.lightGray
        activityIndicator.layer.cornerRadius = 10.0
        self.view.addSubview(self.activityIndicator)
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
        //save for unread message
        self.saveLastReadMessageIfNeeded()
        //do after above line
        self.isViewDisappear = true
        stopAudioPlayer()
        chatBar.stopRecording()
        chatBar.resignAllResponderFromTextView()
        if self.isMovingFromParent {
            self.isLeaveView = true
            self.removeObserver()
        }
        unsubscribingChannel()
        if let _ = alMqttConversationService {
            alMqttConversationService.unsubscribeToConversation()
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.isLeaveChatGroup = true
    }

    override func backTapped() {
        print("back tapped")
        view.endEditing(true)
        self.delegateConversationChatContentAction?.backPageButtonClicked(chatView: self)
        let popVC = navigationController?.popViewController(animated: true)
        //let popVC = navigationController?.popToRootViewController(animated: true)
        if popVC == nil {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func showAccountSuspensionView() {
//        let accountVC = ALKAccountSuspensionController()
//        self.present(accountVC, animated: false, completion: nil)
//        accountVC.closePressed = {[weak self] in
//            _ = self?.navigationController?.popToRootViewController(animated: true)
//        }
    }

    func setupView() {

        unreadScrollButton.isHidden = true
        self.unReadMessageRemindIndicatorView.isHidden = true
        unreadScrollButton.addTarget(self, action: #selector(unreadScrollDownAction(_:)), for: .touchUpInside)

        backgroundView.backgroundColor = configuration.backgroundColor
        prepareTable()
        prepareChatBar()
        //tag: stockviva - set up discrimation view
        self.prepareDiscrimationView()
        replyMessageView.closeButtonTapped = {[weak self] _ in
            self?.viewModel.clearSelectedMessageToReply()
            self?.hideReplyMessageView()
        }
    }
    
    private func setupConstraints() {
        
        let allViews = [backgroundView, tableView, floatingAffiliatePromoButton, floatingShareButton, svMarqueeView, chatBar, unreadScrollButton, unReadMessageRemindIndicatorView, replyMessageView, pinMessageView, discrimationView, activityIndicator]
        
        view.addViewsForAutolayout(views: allViews)

        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50.0).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 70.0).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 70.0).isActive = true
        
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true
        
        pinMessageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pinMessageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        pinMessageView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        pinMessageView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.pinMessageView).isActive = true
        
        tableView.topAnchor.constraint(equalTo: pinMessageView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: discrimationView.topAnchor).isActive = true

        svMarqueeView.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 6.0).isActive = true
        svMarqueeView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        svMarqueeView.widthAnchor.constraint(equalToConstant: 275.0).isActive = true
        svMarqueeView.heightAnchor.constraint(equalToConstant: 27.0).isActive = true
        
        floatingAffiliatePromoButton.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 25.0).isActive = true
        floatingAffiliatePromoButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -15.0).isActive = true
        floatingAffiliatePromoButton.widthAnchor.constraint(equalToConstant: 75.0).isActive = true
        floatingAffiliatePromoButton.heightAnchor.constraint(equalToConstant: 75.0).isActive = true
        
        floatingShareButton.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 25.0).isActive = true
        floatingShareButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -15.0).isActive = true
        floatingShareButton.widthAnchor.constraint(equalToConstant: 75.0).isActive = true
        floatingShareButton.heightAnchor.constraint(equalToConstant: 75.0).isActive = true
        
        //tag: stockviva
        discrimationView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        discrimationView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        discrimationView.bottomAnchor.constraint(equalTo: replyMessageView.topAnchor,constant: 0).isActive = true
        self.discrimationViewHeightConstraint = discrimationView.heightAnchor.constraintEqualToAnchor(constant: 20, identifier: ConstraintIdentifier.discrimationViewHeight)
        self.discrimationViewHeightConstraint?.isActive = true
        
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
    }

    private func prepareTable() {

        let gesture = UITapGestureRecognizer(target: self, action: #selector(tableTapped(gesture:)))
        gesture.numberOfTapsRequired = 1
        tableView.addGestureRecognizer(gesture)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
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
        
        tableView.register(ALKInformationCell.self)
        
        tableView.register(ALKMyDocumentCell.self)
        tableView.register(ALKFriendDocumentCell.self)

        //useless cell
        tableView.register(ALKMyVoiceCell.self)
        tableView.register(ALKFriendVoiceCell.self)
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
        tableView.register(ALKMyContactMessageCell.self)
        tableView.register(ALKFriendContactMessageCell.self)
        tableView.register(SentImageMessageCell.self)
        tableView.register(ReceivedImageMessageCell.self)
        tableView.register(ReceivedFAQMessageCell.self)
        tableView.register(SentFAQMessageCell.self)
        //tag: stockviva
        tableView.register(UINib.init(nibName: "SVALKMySendGiftTableViewCell", bundle: Bundle.applozic), forCellReuseIdentifier: "SVALKMySendGiftTableViewCell")
        tableView.register(UINib.init(nibName: "SVALKFriendSendGiftTableViewCell", bundle: Bundle.applozic), forCellReuseIdentifier: "SVALKFriendSendGiftTableViewCell")
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
        chatBar.accessibilityIdentifier = "chatBar"
        chatBar.action = { [weak self] (action) in
            guard let weakSelf = self else {
                return
            }
            switch action {

            case .sendText(let button, let message, let mentionUserList):
                if message.count < 1 {
                    return
                }
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - user click send text message")
                button.isUserInteractionEnabled = false

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
                
                self?.sendMessageWithClearAllModel(completedBlock: {
                    weakSelf.viewModel.send(message: _tempMsg, mentionUserList:mentionUserList, isOpenGroup: weakSelf.viewModel.isOpenGroup, metadata:self?.configuration.messageMetadata)
                    button.isUserInteractionEnabled = true
                })
            case .chatBarTextChange:
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - chatgroup - user click text changed")
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
            case .sendVoice( _):
                break
//                self?.sendMessageWithClearAllModel(completedBlock: {
//                    weakSelf.viewModel.send(voiceMessage: voice as Data, metadata:self?.configuration.messageMetadata)
//                })
            case .startVideoRecord:
                break
//                if UIImagePickerController.isSourceTypeAvailable(.camera) {
//                    AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
//                        granted in
//                        DispatchQueue.main.async {
//                            if granted {
//                                let imagePicker = UIImagePickerController()
//                                imagePicker.delegate = self
//                                imagePicker.allowsEditing = true
//                                imagePicker.sourceType = .camera
//                                imagePicker.mediaTypes = [kUTTypeMovie as String]
//                                UIViewController.topViewController()?.present(imagePicker, animated: false, completion: nil)
//                            } else {
//                                let msg = weakSelf.localizedString(
//                                    forKey: "EnableCameraPermissionMessage",
//                                    withDefaultValue: SystemMessage.Camera.cameraPermission,
//                                    fileName: weakSelf.localizedStringFileName)
//                                ALUtilityClass.permissionPopUp(withMessage: msg, andViewController: self)
//                            }
//                        }
//                    })
//                } else {
//                    let msg = weakSelf.localizedString(forKey: "CameraNotAvailableMessage", withDefaultValue: SystemMessage.Camera.CamNotAvailable, fileName: weakSelf.localizedStringFileName)
//                    let title = weakSelf.localizedString(forKey: "CameraNotAvailableTitle", withDefaultValue: SystemMessage.Camera.camNotAvailableTitle, fileName: weakSelf.localizedStringFileName)
//                    ALUtilityClass.showAlertMessage(msg, andTitle: title)
//                }
            case .showUploadAttachmentFile:
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - user click open document list")
                let _types:[String] = ["com.adobe.pdf", "public.image"]
                let _vc = ALKCVDocumentPickerViewController(documentTypes: _types, in: UIDocumentPickerMode.import)
                _vc.delegate = weakSelf
                weakSelf.present(_vc, animated: false, completion: nil)
                break
            case .showImagePicker:
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - user click open iamge list")
                guard let vc = ALKCustomPickerViewController.makeInstanceWith(delegate: weakSelf, conversationRequestInfoDelegate:weakSelf, and: weakSelf.configuration)
                    else {
                        return
                }
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                weakSelf.present(vc, animated: false, completion: nil)
            case .showLocation:
                break
//                let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mapView, bundle: Bundle.applozic)
//
//                guard let nav = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
//                guard let mapViewVC = nav.viewControllers.first as? ALKMapViewController else { return }
//                mapViewVC.delegate = self
//                mapViewVC.setConfiguration(weakSelf.configuration)
//                self?.present(nav, animated: true, completion: {})
            case .cameraButtonClicked(let button):
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - user click show camera")
                guard let vc = ALKCustomCameraViewController.makeInstanceWith(delegate: weakSelf, conversationRequestInfoDelegate: weakSelf, and: weakSelf.configuration)
                else {
                    button.isUserInteractionEnabled = true
                    return
                }
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                weakSelf.present(vc, animated: false, completion: nil)
                button.isUserInteractionEnabled = true

            case .shareContact:
                break
//                weakSelf.shareContact()
            default:
                print("Not available")
            }
        }
    }
    
    @objc func tableTapped(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    /// Call this method after proper viewModel initialization
    public func refreshViewController(isClearUnReadMessage:Bool = false, isClearDisplayMessageWithinUser:Bool = true, isClearFocusReplyMessageMode:Bool = false) {
        viewModel.clearViewModel(isClearUnReadMessage:isClearUnReadMessage, isClearDisplayMessageWithinUser:isClearDisplayMessageWithinUser, isClearFocusReplyMessageMode:isClearFocusReplyMessageMode)
        if isClearDisplayMessageWithinUser {
            self.navigationBar.setShowAdminMessageButtonStatus(false)
            self.viewModel.setDisplayMessageWithinUser(nil)
        }
        if isClearUnReadMessage {
            self.scrollingState = .idle
            self.lastScrollingPoint = CGPoint.zero
            self.viewModel.clearUnReadMessageData()
            ALKSVUserDefaultsControl.shared.removeLastReadMessageInfo()
        }
        unreadScrollButton.isHidden = true
        self.unReadMessageRemindIndicatorView.isHidden = true
        tableView.reloadData()
        configureView()
        self.navigationBar.updateContent()
        self.delegateConversationChatContentAction?.updateChatGroupBySpecialResson()
        viewModel.prepareController(isFirstLoad:self.isViewFirstLoadingMessage)
        isFirstTime = false
    }

    func configureView() {
        configureChatBar()
        //Check for group left
        self.mqttConnectRequestFrom = .viewRefresh
        subscribeChannelToMqtt()
    }
    
    
    public func refreshTableView() {
        tableView.reloadData()
    }

    /// Call this before changing viewModel contents
    public func unsubscribingChannel() {
        guard viewModel != nil, alMqttConversationService != nil else { return }
        if !viewModel.isOpenGroup {
            self.alMqttConversationService.unSubscribe(toChannelConversation: viewModel.channelKey)
        } else {
            self.alMqttConversationService.unSubscribe(toOpenChannel: viewModel.channelKey)
        }
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    // Called from the parent VC
    public func sync(message: ALMessage) {
        /// Return if message is sent by loggedin user
        guard self.viewModel != nil && self.isLeaveView == false else { return }
        guard !message.isSentMessage() else { return }
        guard self.viewModel.isUnreadMessageMode == false && self.viewModel.isFocusReplyMessageMode == false else {
            return
        }
        self.viewModel.syncOpenGroupOneMessage(message: message, isNeedOnUnreadMessageModel: self.unreadScrollButton.isHidden == false)
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
        var _needReloadList = true
        //is go to reply view history
        _needReloadList = self.openOrGoToViewMessageFromHistory() == false
        
        if self.viewModel.isUnreadMessageMode || self.viewModel.isFocusReplyMessageMode {
            if _needReloadList {
                //just cancel if user want to read latest message of now
                self.refreshViewController(isClearUnReadMessage: true, isClearDisplayMessageWithinUser:false, isClearFocusReplyMessageMode: true)
            }
        }
        if _needReloadList {
            tableView.scrollToBottom(animated: true)
            unreadScrollButton.isHidden = true
            self.unReadMessageRemindIndicatorView.isHidden = true
        }
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
        case .copy( _, _, let viewModelObj, _):
            UIPasteboard.general.string = viewModelObj?.message ?? ""
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message menu click copy:\(viewModelObj?.rawModel?.dictionary() ?? ["nil":"nil"])")
            break;
        case .reply(let chatGroupHashID, let userHashID, let viewModelObj, let indexPath):
            print("Reply selected")
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message menu click reply:\(viewModelObj?.rawModel?.dictionary() ?? ["nil":"nil"])")
            viewModel.setSelectedMessageToReply(message)
            replyMessageView.update(message: message, configuration:self.configuration)
            showReplyMessageView()
            if let _chatGroupID = chatGroupHashID,
                let _model = viewModelObj {
                self.delegateConversationMessageBoxAction?.didMenuReplyClicked(chatGroupHashID:_chatGroupID, userHashID:userHashID, viewModel: _model, indexPath:indexPath)
            }
            break;
        case .appeal(let chatGroupHashID, let userHashID, let viewModelObj, _):
            print("Appeal selected")
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message menu click appeal:\(viewModelObj?.rawModel?.dictionary() ?? ["nil":"nil"])")
            if let _chatGroupID = chatGroupHashID,
                let _userID = userHashID,
                let _msgID = viewModelObj?.identifier {
                self.delegateConversationMessageBoxAction?.didMenuAppealClicked(chatGroupHashID:_chatGroupID, userHashID:_userID, messageID:_msgID, message:viewModelObj?.message)
            }
            break;
        case .pinMsg(let chatGroupHashID, let userHashID, let viewModel, let indexPath):
            print("PinMsg selected")
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message menu click pin msg:\(viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
            if let _chatGroupID = chatGroupHashID,
                let _model = viewModel {
                self.delegateConversationMessageBoxAction?.didMenuPinMsgClicked(chatGroupHashID:_chatGroupID, userHashID:userHashID, viewModel: _model, indexPath:indexPath)
            }
            break;
        case .deleteMsg(let chatGroupHashID, let userHashID, let viewModel, let indexPath):
            print("DeleteMsg selected")
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message menu click delete msg:\(viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
             if let _chatGroupID = chatGroupHashID,
                let _model = viewModel {
                self.delegateConversationMessageBoxAction?.didMenuDeleteMsgClicked(chatGroupHashID:_chatGroupID, userHashID:userHashID, viewModel: _model, indexPath:indexPath)
                self.viewModel.deleteMessagForAll(viewModel: _model, indexPath: indexPath, startProcess: {
                    self.delegateConversationChatContentAction?.isHiddenFullScreenLoading(false)
                }) { (result, error) in
                    self.delegateConversationChatContentAction?.isHiddenFullScreenLoading(true)
                    if error == nil && result {
                        self.delegateConversationChatContentAction?.messageHadDeleted(viewModel: _model, indexPath: indexPath)
                    }else{
                        self.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.networkProblem)
                    }
                }
            }
            break;
        case .bookmarkMsg(chatGroupHashID: let chatGroupHashID, userHashID: let userHashID, viewModel: let viewModel, indexPath: let indexPath):
            print("DeleteMsg selected")
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message menu click bookmark msg:\(viewModel?.rawModel?.dictionary() ?? ["nil":"nil"])")
            if let _chatGroupID = chatGroupHashID,
                let _model = viewModel {
                self.delegateConversationMessageBoxAction?.didMenuBookmarkMsgClicked(chatGroupHashID:_chatGroupID, userHashID:userHashID, viewModel: _model, indexPath:indexPath)
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
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - scrollTo() - scroll to indexPath:\(indexPath.section), total section:\(self.tableView.numberOfSections)")
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)

    }

//    func postGenericListButtonTapNotification(tag: Int, title: String, template: [ALKGenericListTemplate], key: String) {
//        print("\(title, tag) button selected in generic list")
//        var infoDict = [String: Any]()
//        infoDict["buttonName"] = title
//        infoDict["buttonIndex"] = tag
//        infoDict["template"] = template
//        infoDict["messageKey"] = key
//        infoDict["userId"] = self.viewModel.contactId
//        NotificationCenter.default.post(name: Notification.Name(rawValue: "GenericRichListButtonSelected"), object: infoDict)
//    }

    func quickReplySelected(
        index: Int,
        title: String,
        template: [Dictionary<String, Any>],
        message: ALKMessageViewModel,
        metadata: Dictionary<String, Any>?,
        isButtonClickDisabled: Bool) {
        //print("\(title, index) quick reply button selected")
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

    private func sendNotification(withName: String, buttonName: String, buttonIndex: Int, template: [Dictionary<String, Any>], messageKey: String) {
        var infoDict = [String: Any]()
        infoDict["buttonName"] = title
        infoDict["buttonIndex"] = index
        infoDict["template"] = template
        infoDict["messageKey"] = messageKey
        infoDict["userId"] = self.viewModel.contactId
        NotificationCenter.default.post(name: Notification.Name(rawValue: withName), object: infoDict)
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
            self.loadingStop()
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
        if let _supView = activityIndicator.superview, _supView == self.view {
            view.bringSubviewToFront(activityIndicator)
        }
    }
    
    public func loadingStop() {
        activityIndicator.stopAnimating()
    }

    public func loadingFinished(error: Error?, targetFocusItemIndex:Int, isLoadNextPage:Bool, isFocusTargetAndHighlight:Bool, retryHandler:(()->())?) {
        self.loadingStop()
        let oldSectionCount = tableView.numberOfSections
        //if have error
        if error != nil {
            //show alet for retry
            self.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.networkProblemAndRetry, retryHandler:retryHandler)
            return
        }
        
        tableView.reloadData()
        print("loading finished")
        var _indexPathCell:IndexPath?
        if self.viewModel.isFirstTime {
            if targetFocusItemIndex != -1 {
                let _newSectionCount = self.viewModel.numberOfSections()
                if targetFocusItemIndex < _newSectionCount {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadingFinished - scroll to targetFocusItemIndex:\(targetFocusItemIndex), total section:\(_newSectionCount)")
                    _indexPathCell = IndexPath(row: 0, section: targetFocusItemIndex)
                    self.tableView.scrollToRow(at: _indexPathCell!,
                                               at: isFocusTargetAndHighlight ? .middle : .bottom, animated: false)
                }else{
                    let _sectionIndex = _newSectionCount - 1
                    if _sectionIndex >= 0 {
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadingFinished - scroll to _sectionIndex:\(_sectionIndex), total section:\(_newSectionCount)")
                        _indexPathCell = IndexPath(row: 0, section: _sectionIndex)
                        self.tableView.scrollToRow(at: _indexPathCell! ,
                                                   at: isFocusTargetAndHighlight ? .middle : .bottom, animated: false)
                    }
                }
            }else{
                self.tableView.scrollToBottom(animated: false)
            }
            self.saveLastReadMessageIfNeeded()
            self.viewModel.isFirstTime = false
        }else{
            if targetFocusItemIndex != -1 && isFocusTargetAndHighlight {
                _indexPathCell = IndexPath(row: 0, section: targetFocusItemIndex)
                self.tableView.scrollToRow(at: _indexPathCell!, at: .middle, animated: false)
            }else if isLoadNextPage == false {
                let newSectionCount = self.viewModel.numberOfSections()
                if newSectionCount > oldSectionCount {
                    let offset = newSectionCount - oldSectionCount - 1
                    if offset >= 0 && offset < newSectionCount {
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadingFinished - scroll to offset:\(offset), total section:\(newSectionCount)")
                        tableView.scrollToRow(at: IndexPath(row: 0, section: offset), at: .top, animated: false)
                    }
                }
            }
        }

        //is first time to load message
        if self.isViewFirstLoadingMessage {
            self.isViewFirstLoadingMessage = false
            self.delegateChatGroupLifeCycle?.didFirstLoadCompleted()
        }
        //highlight cell
        if isFocusTargetAndHighlight{
            self.highlightCellOneTime(indexPath: _indexPathCell)
        }
        
        //show / off scroll down button
        if self.viewModel.messageModels.count > 0 {
            let _lastItemIndex = self.viewModel.messageModels.count-1
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadingFinished - rectForRow _lastItemIndex:\(_lastItemIndex), total section:\(self.viewModel.messageModels.count)")
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
        self.loadingStop()
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
            self.loadingStop()
            if needReloadTable == false {
                let newSectionCount = self.viewModel.numberOfSections()
                if newSectionCount > indexPath.section {
                    self.tableView.beginUpdates()
                    self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .fade)
                    self.tableView.endUpdates()
                }else{
                    self.tableView.reloadData()
                }
            }else{
                self.tableView.reloadData()
            }
            //save for unread message
            self.saveLastReadMessageIfNeeded()
        }
    }

    public func removeMessagesAt(indexPath: IndexPath, closureBlock: () -> Void) {
        self.loadingStop()
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
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - moveTableViewToBottom - scroll to indexPath:\(indexPath.section), total section:\(tableView.numberOfSections)")
        if indexPath.section > 0 && indexPath.section < tableView.numberOfSections {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }else{
            var _lastIndex = tableView.numberOfSections - 1
            if _lastIndex < 0 {
                _lastIndex = 0
            }
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - moveTableViewToBottom - adjust the index because the index should under 0, scroll to indexPath:\(_lastIndex), total section:\(tableView.numberOfSections)")
            tableView.scrollToRow(at: IndexPath(row: 0, section: _lastIndex) , at: .bottom, animated: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let sectionCount = self.tableView.numberOfSections
            if indexPath.section <= sectionCount {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - moveTableViewToBottom - scroll to asyncAfter indexPath:\(indexPath.section), total section:\(self.tableView.numberOfSections)")
                if indexPath.section > 0 && indexPath.section < self.tableView.numberOfSections {
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                }else{
                    var _lastIndex = self.tableView.numberOfSections - 1
                    if _lastIndex < 0 {
                        _lastIndex = 0
                    }
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - moveTableViewToBottom - adjust the index because the index should under 0, scroll to asyncAfter indexPath:\(_lastIndex), total section:\(self.tableView.numberOfSections)")
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: _lastIndex) , at: .bottom, animated: false)
                }
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

    @objc open func newMessagesAdded(error: Error?, isFromSyncMessage:Bool, retryHandler:(()->())?) {
        guard error == nil else {
            //show alet for retry
            self.requestToShowAlert(type: ALKConfiguration.ConversationErrorType.networkProblemAndRetry, retryHandler:retryHandler)
            return
        }
        
        updateTableView()
        //save for unread message as last message
        self.saveLastReadMessageAsLastMessge()

        if isViewLoadedFromTappingOnNotification {
            let indexPath: IndexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
            if self.viewModel.isFocusReplyMessageMode == false {
                moveTableViewToBottom(indexPath: indexPath)
            }
            isViewLoadedFromTappingOnNotification = false
        } else {
            if tableView.isCellVisible(section: viewModel.messageModels.count-2, row: 0) { //1 for recent added msg and 1 because it starts with 0
                if self.viewModel.isFocusReplyMessageMode == false {
                    let indexPath: IndexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
                    moveTableViewToBottom(indexPath: indexPath)
                }
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

    public func messageCanSent(at indexPath: IndexPath, mentionUserList:[(hashID:String, name:String)]?) {
        if let _messageModel = self.viewModel.messageForRow(indexPath: indexPath) {
            var _messageReplyId:String = ""
            if let msgMetadata = _messageModel.metadata,
                let replyID = msgMetadata[AL_MESSAGE_REPLY_KEY] as? String {
                _messageReplyId = replyID
            }
            let _messageTypeStr = ALKConfiguration.ConversationMessageTypeForApp.getMessageTypeString(type: _messageModel.messageType)
            self.delegateConversationChatContentAction?.didMessageSent(type: _messageTypeStr, messageID:_messageModel.identifier, messageReplyID:_messageReplyId, message: _messageModel.message, mentionUserList:mentionUserList)
        }
    }
    
    public func updateDisplay(contact: ALContact?, channel: ALChannel?) {
        let profile = viewModel.conversationProfileFrom(contact: contact, channel: channel)
        self.navigationBar.updateContent(profile: profile)
    }

    public func willSendMessage() {
        // Clear reply message and the view
        viewModel.clearSelectedMessageToReply()
        hideReplyMessageView()
    }

    public func updateTyingStatus(status: Bool, userId: String) {
    }

    public func isPassMessageContentChecking() -> Bool {
       return self.delegateConversationChatContentAction?.isAdminUser(nil) ?? false
    }
    
    public func displayMessageWithinUserListModeChanged(result:Bool) {
        self.delegateConversationChatContentAction?.didShowAdminMessageOnlyStatusChanged(result: result)
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
        subscribeChannelToMqtt()
        self.mqttConnectStatus = .connected
        //auto refresh after
        if self.mqttConnectRequestFrom == .appForeground {//if request from app foreground
            self.mqttConnectRequestFrom = .none
            return
        }
        self.mqttConnectRequestFrom = .none
        if self.isViewFirstLoadingMessage == false &&
            self.viewModel.isUnreadMessageMode == false &&
            self.viewModel.isFocusReplyMessageMode == false {
            self.viewModel.syncOpenGroupMessage(isNeedOnUnreadMessageModel:false, isShowLoading:false)
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
    }

    public func updateLastSeen(atStatus alUserDetail: ALUserDetail!) {
        print("Last seen updated")
        guard let contact = contactService.loadContact(byKey: "userId", value: alUserDetail.userId) else {
            return
        }
        guard contact.userId == viewModel.contactId, !viewModel.isGroup else { return }
        //navigationBar.updateStatus(isOnline: contact.connected, lastSeenAt: contact.lastSeenAt)
    }

    public func mqttConnectionClosed() {
        self.mqttConnectStatus = .disConnected
        //reconnection
        if self.isAppToBackground == false && self.isLeaveView == false {
            self.mqttConnectRequestFrom = .mqttDisConnected
            subscribeChannelToMqtt()
        }
        NSLog("MQTT connection closed")
    }

    public func reloadData(forUserBlockNotification userId: String!, andBlockFlag flag: Bool) {
        print("reload data")
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
        self.sendMessageWithClearAllModel {
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

extension ALKConversationViewController: AttachmentDelegate, ALKMediaViewerViewControllerDelegate {
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
            $0.messageType == .photo && $0.fileMetaInfo != nil
            //($0.messageType == .photo || $0.messageType == .video) && ($0.downloadPath() != nil) && ($0.downloadPath()!.1 != nil)
        }

        guard let msg = message as? ALKMessageModel,
            let currentIndex = messageModels.index(of: msg) else { return }
        vc?.delegate = self
        vc?.viewModel = ALKMediaViewerViewModel(
            messages: messageModels,
            currentIndex: currentIndex,
            localizedStringFileName: localizedStringFileName)
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .crossDissolve
        self.present(nav, animated: true, completion: nil)
    }
    
    //ALKMediaViewerViewControllerDelegate
    func refreshMediaCell(message: ALKMessageViewModel) {
        guard let _msgIndexPath = self.viewModel.getMessageIndex(messageId: message.identifier) else { return }
        self.updateMessageAt(indexPath: _msgIndexPath, needReloadTable: false)
    }
    
    func didDownloadImageFailure(){
        self.requestToShowAlert(type: .networkProblem)
    }
}

//MARK: - stockviva
extension ALKConversationViewController {
    public func enableJoinGroupButton(_ isEnable:Bool, isEndEditing:Bool = true){
        //tag: on / off join group button
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
        self.enableShowBlockChatMode = isEnable
        if isEndEditing {
            view.endEditing(true)
            self.chatBar.resignAllResponderFromTextView()
        }
        self.chatBar.hiddenBlockChatButton(!self.enableShowBlockChatMode)
    }
    
    private func prepareAllCustomView() {
        self.refreshFloatingButtonView()
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
    
    private func presentMessageDetail(isPinMsg:Bool = false, userName:String?, userIconUrl:String?, isWelcomeUserJoinMode:Bool = false, bigTitle:String? = nil, subTitle:String? = nil, viewModel: ALKMessageViewModel?, isShowPromotionImage:Bool = false, completed:((_ isSuccessful:Bool)->())? = nil){
        let _storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.svMessageDetailView, bundle: Bundle.applozic)
        var _presentVC:ALKSVBaseMessageDetailViewController?
        let _msgType = isPinMsg ? viewModel?.getContentTypeForPinMessage() : viewModel?.messageType
        if _msgType == .photo {
            if let _vc = _storyboard.instantiateViewController(withIdentifier: "ALKSVImageMessageDetailViewController") as? ALKSVImageMessageDetailViewController {
                _vc.downloadTapped = {[weak self] value in
                    if let _viewModel = viewModel {
                        self?.viewModel.downloadAttachment(message: _viewModel, viewController: _vc)
                    }
                }
                _vc.imageFileUpdateDelegate = self
                _presentVC = _vc
            }
        }else if _msgType == .document {
            if let _vc = _storyboard.instantiateViewController(withIdentifier: "ALKSVDocumentMessageDetailViewController") as? ALKSVDocumentMessageDetailViewController {
                _vc.downloadTapped = {[weak self] value in
                    if let _viewModel = viewModel {
                        self?.viewModel.downloadAttachment(message: _viewModel, viewController: _vc)
                    }
                }
                _vc.documentFileUpdateDelegate = self
                _presentVC = _vc
            }
        }else{//default text
            if _msgType == .text || isWelcomeUserJoinMode {
                if let _vc = _storyboard.instantiateViewController(withIdentifier: "ALKSVMessageDetailViewController") as? ALKSVMessageDetailViewController {
                    _vc.messageViewLinkClicked = { (url, viewModel) in
                        if self.configuration.enableOpenLinkInApp {
                            self.delegateConversationChatContentAction?.openLink(url: url, viewModel:viewModel, sourceView: _vc, isPushFromSourceView:true)
                        }
                    }
                    _presentVC = _vc
                }
            }
        }
        
        if let _pVC = _presentVC {
            _pVC.configuration = self.configuration
            _pVC.isViewFromPinMessage = isPinMsg
            _pVC.userName = userName
            _pVC.userIconUrl = userIconUrl
            _pVC.viewModel = viewModel
            _pVC.isShowPromotionImage = isShowPromotionImage
            _pVC.isWelcomeUserJoinMode = isWelcomeUserJoinMode
            _pVC.bigTitle = bigTitle
            _pVC.subTitle = subTitle
            _pVC.delegate = self
            _pVC.modalPresentationStyle = .overCurrentContext
            _pVC.modalTransitionStyle = .crossDissolve
            self.present(_pVC, animated: true) {
                completed?(true)
            }
        }else{
            completed?(false)
        }
    }
    
    func didReplyClickedInCell(currentMessage: ALKMessageViewModel?, replyMessage: ALKMessageViewModel?){
        guard let _replyMessage = replyMessage else {
            return
        }
        if self.viewModel.isDisplayMessageWithinUserListMode == false {
            if let _indexPath = self.viewModel.getMessageIndex(messageId: _replyMessage.identifier) {
                self.viewModel.addReplyMessageViewHistory(currentViewMessage: currentMessage, replyMessage: replyMessage)
                let _cellIndexPath = IndexPath(row: 0, section: _indexPath.section)
                //if ready loaded, goto that row
                self.tableView.scrollToRow(at: _cellIndexPath , at: .middle, animated: true)
                self.highlightCellOneTime(indexPath: _cellIndexPath)
            }else if let _replyMsgCreateTime = _replyMessage.createdAtTime {
                self.viewModel.addReplyMessageViewHistory(currentViewMessage: currentMessage, replyMessage: replyMessage)
                //reload and go to reply message
                self.viewModel.reloadOpenGroupFocusReplyMessage(targetMessageInfo: (id: _replyMessage.identifier, createTime: _replyMsgCreateTime))
            }
        }else{
            var _userDisplayName:String? = nil
            var _userIconUrl:String? = nil
            if _replyMessage.isMyMessage {
                _userDisplayName = ALUserDefaultsHandler.getDisplayName()
                _userIconUrl = ALUserDefaultsHandler.getProfileImageLinkFromServer()
                if _userDisplayName == nil {
                    _userDisplayName = ""
                }
                if _userIconUrl == nil {
                    _userIconUrl = ""
                }
            }
            self.presentMessageDetail(userName: _userDisplayName, userIconUrl: _userIconUrl, viewModel: _replyMessage)
        }
    }
    
    func openOrGoToViewMessageFromHistory() -> Bool {
        //get last messages
        var _lastViewMessage:ALKMessageViewModel?
        if let _lastIndex = self.tableView.indexPathsForVisibleRows?.last {
            _lastViewMessage = self.viewModel.messageForRow(indexPath: _lastIndex)
        }
        //get last reply message
        guard let _message = self.viewModel.getLatestReplyMessageViewHistory(afterMessage:_lastViewMessage) else {
            return false
        }
        var _result = false
        if let _indexPath = self.viewModel.getMessageIndex(messageId: _message.identifier) {
            let _cellIndexPath = IndexPath(row: 0, section: _indexPath.section)
            //if ready loaded, goto that row
            self.tableView.scrollToRow(at: _cellIndexPath , at: .middle, animated: true)
            self.highlightCellOneTime(indexPath: _cellIndexPath)
            _result = true
        }else if let _replyMsgCreateTime = _message.createdAtTime {
            //reload and go to reply message
            self.viewModel.reloadOpenGroupFocusReplyMessage(targetMessageInfo: (id: _message.identifier, createTime: _replyMsgCreateTime))
            _result = true
        }
        return _result
    }
    
    func sendMessageWithClearAllModel(completedBlock:@escaping ()->Void){
        //check model
        if self.viewModel.isUnreadMessageMode || self.viewModel.isDisplayMessageWithinUserListMode || self.viewModel.isFocusReplyMessageMode{
            self.navigationBar.setShowAdminMessageButtonStatus(false)
            self.viewModel.messageSendUnderClearAllModel(startProcess: {
                self.scrollingState = .idle
                self.lastScrollingPoint = CGPoint.zero
                self.loadingStarted()
            }) {//completed
                self.loadingStop()
                completedBlock()
            }
        }else{
            completedBlock()
        }
    }
}

//MARK: - stockviva - navigationBar control - (SVALKConversationNavBarDelegate)
extension ALKConversationViewController: SVALKConversationNavBarDelegate {
    
    private func setupNavigation() {
        self.navigationBar.delegate = self
        self.navigationBar.navigationItem = self.navigationItem
        self.navigationBar.configuration = self.configuration
        self.navigationBar.viewModel = self.viewModel
        self.navigationBar.setUpNavigationBar()
    }
    
    public func hiddenGroupMuteButton(_ hidden:Bool){
        self.navigationBar.hiddenGroupMuteButton(hidden)
    }
    
    //SVALKConversationNavBarDelegate
    public func getNavigationBarSubTitle() -> String? {
        return self.delegateConversationChatContentAction?.getGroupTitle(chatView: self)
    }
    
    public func didNavigationBarItemClicked(actionItem: SVALKConversationNavBar.ALKSVNavigationBarItem, sender: Any?) {
        switch actionItem {
        case .backPage:
            backTapped()
            break
        case .title:
            view.endEditing(true)
            self.chatBar.resignAllResponderFromTextView()
            //for custom show detail view
            if self.configuration.enableCustomeGroupDetail {
                guard isGroupDetailActionEnabled else { return }
                self.delegateConversationChatContentAction?.groupTitleViewClicked(chatView: self)
                return
            }
            break
        case .refreshView:
            self.refreshViewController()
            break
        case .shareGroup:
            self.chatBar.resignAllResponderFromTextView()
            guard let _sender = sender as? UIButton else {
                return
            }
            self.delegateConversationChatContentAction?.shareGroupButtonClicked(chatView: self, button: _sender)
            break
        case .showAdminMsgOnly:
            view.endEditing(true)
            self.chatBar.resignAllResponderFromTextView()
            guard let _sender = sender as? UIButton else {
                return
            }
            self.delegateConversationChatContentAction?.showAdminMessageOnlyButtonClicked(chatView: self, button: _sender)
            break
        case .searchMessage:
            self.delegateConversationChatContentAction?.searchMessageButtonClicked()
            break
        case .customRightMenu:
            view.endEditing(true)
            self.chatBar.resignAllResponderFromTextView()
            self.delegateConversationChatContentAction?.rightMenuClicked(chatView: self)
            break
        case .defaultRightMenu:
            let channelId = (viewModel.channelKey != nil) ? String(describing: viewModel.channelKey!) : ""
            let contactId = viewModel.contactId ?? ""
            let info: [String: Any] = ["ChannelId": channelId, "ContactId": contactId, "ConversationVC": self]

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RightNavBarConversationViewAction"), object: info)
            break
        }
    }
}

//MARK: - stockviva (ALKSVPinMessageViewDelegate)
extension ALKConversationViewController: ALKSVPinMessageViewDelegate {
    public func showPinMessageBarView(isHidden:Bool, isHiddenNewMsgIndecator:Bool = true, pinMsgItem: SVALKPinMessageItem? = nil){
        if let _pinMsgItem = pinMsgItem, let _viewModel = _pinMsgItem.messageModel, isHidden == false {
            let _currentPinMsgBar:Bool = self.pinMessageView.isHidden
            self.pinMessageView.isHidden = isHidden
            let height: CGFloat = isHidden ? 0 : Padding.PinMessageView.height
            self.pinMessageView.constraint(withIdentifier: ConstraintIdentifier.pinMessageView)?.constant = height
            self.pinMessageView.updateContent(isHiddenNewMsgIndecator: isHiddenNewMsgIndecator, pinMsgItem: _pinMsgItem, viewModel: _viewModel)
            if _currentPinMsgBar != isHidden {
                var _newPosY = self.tableView.contentOffset.y + height
                if (self.tableView.contentOffset.y + (self.tableView.bounds.size.height - height)) > self.tableView.contentSize.height {
                    _newPosY = self.tableView.contentSize.height - (self.tableView.bounds.size.height - height)
                }
                if _newPosY > 0 {
                    self.tableView.setContentOffset(CGPoint(x: self.tableView.contentOffset.x, y: _newPosY ), animated: false)
                }
            }
        }else{
            self.pinMessageView.isHidden = true
            let height: CGFloat = 0
            self.pinMessageView.constraint(withIdentifier: ConstraintIdentifier.pinMessageView)?.constant = height
        }
    }
    
    public func markReadedPinMessageInBarView(_ isReaded:Bool){
        self.pinMessageView.isHiddenNewMessageIndecator(isReaded)
    }
    
    public func showPinMessageDialogManually(isShowPromotionImage:Bool = false, isWelcomeUserJoinMode:Bool = false, bigTitle:String? = nil, subTitle:String? = nil, completed:((_ isSuccessful:Bool)->())? = nil){
        if self.pinMessageView.isHidden && isWelcomeUserJoinMode == false {
            completed?(false)
            return
        }
        //show message
        self.presentMessageDetail(isPinMsg:true, userName:self.pinMessageView.pinMsgItem?.userName, userIconUrl:self.pinMessageView.pinMsgItem?.userIconUrl, isWelcomeUserJoinMode:isWelcomeUserJoinMode, bigTitle:bigTitle, subTitle:subTitle, viewModel: self.pinMessageView.viewModel, isShowPromotionImage:isShowPromotionImage, completed:completed)
    }
    
    func didPinMessageBarClicked(pinMsgItem: SVALKPinMessageItem?, viewModel: ALKMessageViewModel?) {
        if self.isEnablePaidFeature() == false {
            self.requestToShowAlert(type: .funcNeedPaidForPinMsg)
            return
        }
        //show message
        self.delegateConversationChatContentAction?.didPinMessageBarClicked()
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
extension ALKConversationViewController: UIDocumentPickerDelegate, ALKFileUploadConfirmViewControllerDelegate, ALKDocumentViewerControllerDelegate {
    //UIDocumentPickerDelegate
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.showDocumentConfirmPage(urls: [url])
    }
    
    @available(iOS 11.0, *)
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.showDocumentConfirmPage(urls: urls)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //none
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
        self.sendMessageWithClearAllModel {
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
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                if let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyDocumentCell {
                    self.viewModel.uploadFile(view: cell, indexPath: newIndexPath)
                }else if let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyPhotoPortalCell {
                    self.viewModel.uploadImage(view: cell, indexPath: newIndexPath)
                }
            }
        }
    }
    
    //ALKDocumentViewerControllerDelegate
    func refreshDocumentCell(message: ALKMessageViewModel) {
        guard let _msgIndexPath = self.viewModel.getMessageIndex(messageId: message.identifier) else { return }
        self.updateMessageAt(indexPath: _msgIndexPath, needReloadTable: false)
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
        view.endEditing(true)
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatBarAction?.joinGroupButtonClicked(chatBar: chatBar, chatView:self)
    }
    
    public func chatBarRequestBlockChatButtonClicked(chatBar:ALKChatBar, chatView:UIViewController?) {
        view.endEditing(true)
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatBarAction?.blockChatButtonClicked(chatBar: chatBar, chatView:self)
    }
    
    public func chatBarRequestUserEnteredSpecialCharacterKeyDetected(key:String) {
        self.delegateConversationChatBarAction?.didUserEnteredSpecialCharacterKey(key:key)
    }
    
    public func chatBarRequestSendContentDetectedSpecialKeyword(type: ALKConfiguration.ConversationMessageKeywordType, content: String) -> Bool {
        return self.delegateConversationChatBarAction?.didSendContentDetectedSpecialKeyword(type: type, content: content) ?? false
    }
    
    public func chatBarRequestSearchStockCode(key:String) -> [(code:String, name:String)]? {
        return self.delegateConversationChatBarAction?.searchStockCodeInChatBar(key:key)
    }
    
    public func chatBarRequestSuggestionStockCodeClicked(code:String, name:String) {
        self.delegateConversationChatBarAction?.suggestionStockCodeClicked(code:code, name:name)
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
        return self.delegateConversationChatContentAction?.isAdminUser(nil) ?? false
    }
    
    public func isEnableBookmarkMenuItem() -> Bool {
        return self.enableBookmarkMsgFeture
    }
    
    public func requestToShowAlert(type:ALKConfiguration.ConversationErrorType, retryHandler:(()->())? = nil){
        self.delegateConversationChatContentAction?.showAlert(type:type, retryHandler: retryHandler)
    }
    
    public func updateMessageModelData(messageModel:ALKMessageViewModel?, isUpdateView:Bool) {
        if let _rawModel = messageModel?.rawModel {
            self.viewModel.updateMessageContent(updatedMessage: _rawModel, isUpdateView: isUpdateView)
        }
    }
    public func isAdminUserMessage(userHashId:String?) -> Bool {
        return self.delegateConversationChatContentAction?.isAdminUser(userHashId) ?? false
    }
}

//MARK: - stockviva unread message
extension ALKConversationViewController {
    
    func saveLastReadMessageIfNeeded(){
        if self.isViewDisappear || self.viewModel.isDisplayMessageWithinUserListMode {
            return
        }
        let _maxYForVisableContent = self.tableView.contentOffset.y + self.tableView.bounds.size.height
        for _cellIndex in self.tableView.indexPathsForVisibleRows?.reversed() ?? [] {
            let _cellPos = self.tableView.rectForRow(at: _cellIndex)
            let _cellMinHeightOffset = _cellPos.height / 2.5
            if (_cellPos.maxY - _cellMinHeightOffset) <= _maxYForVisableContent {
                if let _cellItem =  self.viewModel.messageForRow(indexPath: _cellIndex),
                    let _createDate = _cellItem.createdAtTime,
                    let _chKey = self.viewModel.channelKey,
                    let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey,
                    (_cellItem.isSent == true || _cellItem.isMyMessage == false)  {
                    ALKSVUserDefaultsControl.shared.saveLastReadMessageInfo(chatGroupId: _chatGroupId, messageId: _cellItem.identifier, createTime: _createDate.intValue)
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - saveLastReadMessageIfNeeded - rectForRow _cellIndex:\(_cellIndex), total section:\(self.tableView.numberOfSections), chatgroup:\(_chatGroupId), msgId:\(_cellItem.identifier)")
                    break
                }
            }
        }
    }
    
    func saveLastReadMessageAsLastMessge(){
        if self.isViewDisappear || self.viewModel.isDisplayMessageWithinUserListMode {
            return
        }
        if let _cellItem =  self.viewModel.messageModels.last,
            let _createDate = _cellItem.createdAtTime,
            let _chKey = self.viewModel.channelKey,
            let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey,
            (_cellItem.isSent == true || _cellItem.isMyMessage == false) {
            ALKSVUserDefaultsControl.shared.saveLastReadMessageInfo(chatGroupId: _chatGroupId, messageId: _cellItem.identifier, createTime: _createDate.intValue)
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

//MARK: - stockviva (reply message)
extension ALKConversationViewController {
    func highlightCellOneTime(indexPath:IndexPath?, retryCount:Int = 0){
        if let _cellIndex = indexPath,
            let _cell = self.tableView.cellForRow(at: _cellIndex) {
            _cell.setHighlighted(true, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                _cell.setHighlighted(false, animated: true)
            }
        }else if retryCount < 6 {//try 3 second
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.highlightCellOneTime(indexPath:indexPath, retryCount: retryCount + 1 )
            }
        }
    }
}


//MARK: - stockviva (floating button)
extension ALKConversationViewController {
    public func refreshFloatingButtonView(){
        if self.configuration.isShowFloatingAffiliatePromotionButton {
            self.configuration.isShowFloatingShareGroupButton = false
        }
        self.hiddenFloatingShareButton(!self.configuration.isShowFloatingShareGroupButton)
        self.hiddenFloatingAffiliatePromotionButton(!self.configuration.isShowFloatingAffiliatePromotionButton)
    }
    
    private func hiddenFloatingShareButton(_ hidden:Bool){
        self.floatingShareButton.isHidden = hidden
        if let _image = self.delegateConversationChatContentAction?.loadingFloatingShareButton(),
            self.floatingShareButton.isHidden == false {
            self.configuration.isShowFloatingShareGroupButton = true
            self.floatingShareButton.setImage(_image, for: .normal)
        }else{
            self.floatingShareButton.isHidden = true
            self.configuration.isShowFloatingShareGroupButton = false
        }
    }
    
    private func hiddenFloatingAffiliatePromotionButton(_ hidden:Bool){
        self.floatingAffiliatePromoButton.isHidden = hidden
        if let _imageUrl = self.delegateConversationChatContentAction?.loadingFloatingAffiliatePromotionButtonUrl(),
            self.floatingAffiliatePromoButton.isHidden == false {
            self.configuration.isShowFloatingAffiliatePromotionButton = true
            self.floatingAffiliatePromoButton.kf.setImage(with: _imageUrl, for: .normal)
        }else{
            self.floatingAffiliatePromoButton.isHidden = true
            self.configuration.isShowFloatingAffiliatePromotionButton = false
        }
    }
    
    public func isHiddenFloatingShareTip(_ isHidden:Bool) {
        if let _btnShare = self.navigationBar.getRightBarItemButton(item: .shareGroup),
            let _floatingShareTipInfo = self.delegateConversationChatContentAction?.loadingFloatingShareTip(),
            let _inViewPoint = self.navigationItem.rightBarButtonItem?.customView?.convert(_btnShare.frame.origin, to: self.view),
            isHidden == false {
            let _sizeOfArrow = CGSize(width: 19.0, height: 8.0)
            let _centerXWithTargetArrow = ( _inViewPoint.x + (_btnShare.frame.size.width / 2.0) ) - (_sizeOfArrow.width / 2.0)
            let _centerYWithTargetArrow = (self.navigationController?.navigationBar.frame.minY ?? 0) + abs(_inViewPoint.y)
            
            var _centerXWithTargetButton = ( _inViewPoint.x + (_btnShare.frame.size.width / 2.0) ) - (_floatingShareTipInfo.size.width / 2.0)
            _centerXWithTargetButton = min(_centerXWithTargetButton, (self.view.frame.size.width - _floatingShareTipInfo.size.width) )
            let _centerYWithTargetButton = _centerYWithTargetArrow + _sizeOfArrow.height
            
            self.floatingShareTipButtonArrowImg.tintColor = _floatingShareTipInfo.bgColor
            self.floatingShareTipButtonArrowImg.frame.origin = CGPoint(x: _centerXWithTargetArrow, y: _centerYWithTargetArrow)
            self.floatingShareTipButtonArrowImg.frame.size = _sizeOfArrow
            self.floatingShareTipButtonArrowImg.alpha = 0.0
            self.floatingShareTipButtonArrowImg.isHidden = false
            
            self.floatingShareTipButton.setTitle(_floatingShareTipInfo.title, for: .normal)
            self.floatingShareTipButton.setBackgroundColor(_floatingShareTipInfo.bgColor)
            self.floatingShareTipButton.titleEdgeInsets = _floatingShareTipInfo.titleEdgeInsets ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.floatingShareTipButton.frame.origin = CGPoint(x: _centerXWithTargetButton, y: _centerYWithTargetButton)
            self.floatingShareTipButton.frame.size = _floatingShareTipInfo.size
            self.floatingShareTipButton.layer.cornerRadius = _floatingShareTipInfo.size.height / 2.0
            self.floatingShareTipButton.alpha = 0.0
            self.floatingShareTipButton.isHidden = false
            
            let _currentWindow: UIWindow? = UIApplication.shared.keyWindow
            _currentWindow?.addSubview(self.floatingShareTipButtonArrowImg)
            _currentWindow?.addSubview(self.floatingShareTipButton)
            _currentWindow?.bringSubviewToFront(self.floatingShareTipButtonArrowImg)
            _currentWindow?.bringSubviewToFront(self.floatingShareTipButton)
            //animation
            UIView.animate(withDuration: 0.4, animations: {
                self.floatingShareTipButtonArrowImg.alpha = 1.0
                self.floatingShareTipButton.alpha = 1.0
            }) { (isSuccessful) in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(_floatingShareTipInfo.dismissSecond) ) {
                    UIView.animate(withDuration: 0.4, animations: {
                        self.floatingShareTipButtonArrowImg.alpha = 0.0
                        self.floatingShareTipButton.alpha = 0.0
                    }) { (isSuccessful) in
                        self.floatingShareTipButton.isHidden = true
                        self.floatingShareTipButtonArrowImg.isHidden = true
                        if self.floatingShareTipButton.superview != nil {
                            self.floatingShareTipButton.removeFromSuperview()
                        }
                        if self.floatingShareTipButtonArrowImg.superview != nil {
                            self.floatingShareTipButtonArrowImg.removeFromSuperview()
                        }
                    }
                }
            }
        }else{
            self.floatingShareTipButton.isHidden = true
            self.floatingShareTipButtonArrowImg.isHidden = true
            if self.floatingShareTipButton.superview != nil {
                self.floatingShareTipButton.removeFromSuperview()
            }
            if self.floatingShareTipButtonArrowImg.superview != nil {
                self.floatingShareTipButtonArrowImg.removeFromSuperview()
            }
        }
    }
}

//MARK: - stockviva (display admin message)
extension ALKConversationViewController {
    
    @objc func didFloatingAffiliatePromotionButtonTouchUpInside(_ sender: UIButton) {
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatContentAction?.didFloatingAffiliatePromotionButtonClicked(chatView: self, button: sender)
    }
    
    @objc func didFloatingShareButtonTouchUpInside(_ sender: UIButton) {
        self.chatBar.resignAllResponderFromTextView()
        self.delegateConversationChatContentAction?.didFloatingShareButtonClicked(chatView: self, button: sender)
        self.hiddenFloatingShareButton(true)
    }
    
    public func reloadMessageWithTargetUser(adminUserIdList:[String]?){
        self.viewModel.setDisplayMessageWithinUser(adminUserIdList)
        self.refreshViewController(isClearUnReadMessage: true, isClearDisplayMessageWithinUser: false, isClearFocusReplyMessageMode: true)
        tableView.scrollToBottom(animated: true)
    }
}

//MARK: - stockviva SVALKMarqueeViewDelegate
extension ALKConversationViewController : SVALKMarqueeViewDelegate{
    public func marqueeListDisplayCompleted() {
        self.delegateConversationChatContentAction?.didSendGiftHistoryDisplayCompleted()
    }
    
    public func viewDidClosed(isUserClick:Bool, isTimeUp:Bool) {
        self.delegateConversationChatContentAction?.didSendGiftHistoryViewClosed(isUserClick:isUserClick, isTimeUp: isTimeUp)
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

