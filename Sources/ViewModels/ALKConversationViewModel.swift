//
//  ALKConversationViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Applozic

public protocol ALKConversationViewModelDelegate: class {
    func loadingStarted()
    func loadingStop()
    func loadingFinished(error: Error?, targetFocusItemIndex:Int, isLoadNextPage:Bool, isFocusTargetAndHighlight:Bool)
    func messageUpdated()
    func updateMessageAt(indexPath: IndexPath, needReloadTable:Bool)
    func removeMessagesAt(indexPath: IndexPath, closureBlock:()->Void)
    func newMessagesAdded()
    func messageSent(at: IndexPath)
    func messageCanSent(at: IndexPath, mentionUserList:[(hashID:String, name:String)]?)
    func updateDisplay(contact: ALContact?, channel: ALChannel?)
    func willSendMessage()
    func updateTyingStatus(status: Bool, userId: String)
    func isPassMessageContentChecking() -> Bool
    func displayMessageWithinUserListModeChanged(result:Bool)
}

// swiftlint:disable:next type_body_length
open class ALKConversationViewModel: NSObject, Localizable {

    fileprivate var localizedStringFileName: String!

    // MARK: - Inputs
    open var contactId: String?
    open var channelKey: NSNumber?
    open var channelInfo: ALChannel?

    // For topic based chat
    open var conversationProxy: ALConversationProxy?

    weak public var delegate: ALKConversationViewModelDelegate?

    // MARK: - Outputs
    open var isFirstTime = true

    open var isGroup: Bool {
        guard channelKey != nil else {
            return false
        }
        return true
    }

    open var messageModels: [ALKMessageModel] = []

    open var richMessages: [String: Any] = [:]

    open var isOpenGroup: Bool {
        let alChannelService = ALChannelService()
        guard let channelKey = channelKey,
            let alchannel = alChannelService.getChannelByKey(channelKey) else {
            return false
        }
        return alchannel.type == 6
    }

    private var conversationId: NSNumber? {
        return conversationProxy?.id
    }

    private lazy var chatId: String? = conversationId?.stringValue ?? channelKey?.stringValue ?? contactId

    private let maxWidth = UIScreen.main.bounds.width
    private var alMessageWrapper = ALMessageArrayWrapper()

    private var alMessages: [ALMessage] = []

    private let mqttObject = ALMQTTConversationService.sharedInstance()

    /// Message on which reply was tapped.
    private var selectedMessageForReply: ALKMessageViewModel?

    //tag: stockviva
    private let defaultValue_minMessageRequired:Int = 10
    private let defaultValue_requestMessagePageSize:Int = 20
    private let defaultValue_requestMessageHalfPageSize:Int = 10
    private var isLoadingAllMessage = false
    private var isLoadingEarlierMessage = false
    private var isLoadingLatestMessage = false
    private var unreadMessageSeparator:ALMessage = ALMessage()
    public var targetOpenMessageForFirstOpen:(id: String, createTime: Int)?
    public var isUnreadMessageMode = false
    public var isFocusReplyMessageMode = false
    public var lastUnreadMessageKey:String? = nil
    public var delegateConversationChatContentAction:ConversationChatContentActionDelegate?
    public var delegateChatGroupLifeCycle:ConversationChatContentLifeCycleDelegate?
    public var isDisplayMessageWithinUserListMode = false
    public var messageDisplayWithinUserList:[String]?
    public var replyMessageViewHistoryList:[ALKMessageViewModel] = []

    // MARK: - Initializer
    public required init(
        contactId: String?,
        channelKey: NSNumber?,
        conversationProxy: ALConversationProxy? = nil,
        localizedStringFileName: String!,
        channelInfo: ALChannel? = nil) {
        self.contactId = contactId
        self.channelKey = channelKey
        self.conversationProxy = conversationProxy
        self.localizedStringFileName = localizedStringFileName
        self.channelInfo = channelInfo
    }

    // MARK: - Public methods
    public func prepareController(isFirstLoad:Bool) {

        // Load messages from server in case of open group
        guard !isOpenGroup else {
            delegate?.loadingStarted()
            if let _targetOpenMsg = self.targetOpenMessageForFirstOpen {
                self.targetOpenMessageForFirstOpen = nil
                self.reloadOpenGroupFocusReplyMessage(targetMessageInfo: _targetOpenMsg, isFirstLoad:isFirstLoad)
            }else{
                self.loadOpenGroupMessageWithUnreadModel(isFirstLoad:isFirstLoad)
            }
            return
        }
        self.messageSendUnderClearAllModel(isFirstLoad: isFirstLoad, startProcess: {
            self.delegate?.loadingStarted()
        }) {
            self.delegate?.loadingStop()
        }
    }

    public func addToWrapper(message: ALMessage) {
        guard !alMessageWrapper.contains(message: message) else { return }
        self.alMessageWrapper.addALMessage(toMessageArray: message)
        self.alMessages.append(message)
        self.messageModels.append(message.messageModel)
    }

    func clearViewModel(isClearUnReadMessage:Bool = true,
                        isClearDisplayMessageWithinUser:Bool = true,
                        isClearFocusReplyMessageMode:Bool = true) {
        self.isFirstTime = true
        if isClearUnReadMessage {
            self.clearUnReadMessageData()
        }
        if isClearDisplayMessageWithinUser {
            self.setDisplayMessageWithinUser(nil)
        }
        if isClearFocusReplyMessageMode {
            self.clearFocusReplyMessageMode()
        }
        self.isLoadingAllMessage = false
        self.isLoadingEarlierMessage = false
        self.isLoadingLatestMessage = false
        self.messageModels.removeAll()
        self.alMessages.removeAll()
        self.richMessages.removeAll()
        self.alMessageWrapper = ALMessageArrayWrapper()
        HeightCache.shared.clearAll()
    }

    open func groupProfileImgUrl() -> String {
        guard let message = alMessages.last, let imageUrl = message.avatarGroupImageUrl else {
            return ""
        }
        return imageUrl
    }

    open func groupName() -> String {
        guard let message = alMessages.last else {
            return ""
        }
        _ = alMessages.first?.createdAt
        return message.groupName
    }

    open func groupKey() -> NSNumber? {
        guard let message = alMessages.last else {
            return nil
        }
        return message.groupId
    }

    open func friends() -> [ALKFriendViewModel] {
        let alChannelService = ALChannelService()

        // TODO:  This is a workaround as other method uses closure.
        // Later replace this with:
        // alChannelService.getChannelInformation(, orClientChannelKey: , withCompletion: )
        guard let message = alMessages.last, let alChannel = alChannelService.getChannelByKey(message.groupId) else {
            return []
        }

        guard let members = alChannel.membersId else { return [] }
        let membersId = members.map { ($0 as? String) }
        let alContactDbService = ALContactDBService()
        let alContacts = membersId.map { alContactDbService.loadContact(byKey: "userId", value: $0) }
        let models = alContacts.filter { $0?.userId != ALUserDefaultsHandler.getUserId()}.map { ALKFriendViewModel.init(identity: $0!) }
        print("all models: ", models.count)
        return models
    }

    open func numberOfSections() -> Int {
        return messageModels.count
    }

    open func numberOfRows(section: Int) -> Int {
        return 1

    }

    open func messageForRow(indexPath: IndexPath) -> ALKMessageViewModel? {
        guard indexPath.section < messageModels.count && indexPath.section >= 0 else { return nil }
        return messageModels[indexPath.section]
    }

    open func replyMessageFor(message: ALKMessageViewModel) -> ALKMessageViewModel? {
        guard let metadata = message.metadata,
            let replyKey = metadata[AL_MESSAGE_REPLY_KEY] as? String
        else {
            return nil
        }
        return messageForRow(identifier: replyKey) ?? ALMessageService().getALMessage(byKey: replyKey)?.messageModel
    }

    open func quickReplyDictionary(message: ALKMessageViewModel?,indexRow row: Int) -> Dictionary<String,Any>? {

        guard let metadata = message?.metadata else {
            return Dictionary<String,Any>()
        }

        let payload = metadata["payload"] as? String

        let data = payload?.data
        var jsonArray : [Dictionary<String,Any>]?

        do {
            jsonArray = (try JSONSerialization.jsonObject(with: data!, options : .allowFragments) as? [Dictionary<String,Any>])
            return   jsonArray?[row]
        } catch let error as NSError {
            print(error)
        }
        return Dictionary<String,Any>()
    }

    open func getSizeForItemAt(row: Int,withData: Dictionary<String,Any>) -> CGSize {

        let size = (withData["title"] as? String)?.size(withAttributes: [NSAttributedString.Key.font: Font.normal(size: 14.0).font()])
        let newSize = CGSize(width: (size?.width)!+46.0, height: 50.0)
        return newSize
    }

    open func messageForRow(identifier: String) -> ALKMessageViewModel? {
        guard let messageModel = messageModels.filter({$0.identifier == identifier}).first else {return nil}
        return messageModel
    }

    func sectionFor(identifier: String) -> Int? {
        return messageModels.firstIndex { $0.identifier == identifier }
    }

    open func heightForRow(indexPath: IndexPath, cellFrame: CGRect) -> CGFloat {
        if indexPath.section >= messageModels.count {
            return 0
        }
        let messageModel = messageModels[indexPath.section]
        if let height = HeightCache.shared.getHeight(for: messageModel.identifier) {
            return height
        }
        
        let replyMessage = replyMessageFor(message: messageModel)
        switch messageModel.messageType {
        case .text, .html, .email:
            if messageModel.isMyMessage {
                let height = ALKMyMessageCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                return height.cached(with: messageModel.identifier)
            } else {
                let height = ALKFriendMessageCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                return height.cached(with: messageModel.identifier)
            }
        case .photo:
            if messageModel.isMyMessage {
                if messageModel.ratio < 1 {
                    let heigh = ALKMyPhotoPortalCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                    return heigh.cached(with: messageModel.identifier)
                } else {
                    let heigh = ALKMyPhotoLandscapeCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                    return heigh.cached(with: messageModel.identifier)
                }
            } else {
                if messageModel.ratio < 1 {
                    let heigh = ALKFriendPhotoPortalCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                    return heigh.cached(with: messageModel.identifier)
                } else {
                    let heigh = ALKFriendPhotoLandscapeCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                    return heigh.cached(with: messageModel.identifier)
                }
            }
        case .voice:
            var height: CGFloat =  0
            if messageModel.isMyMessage {
                height = ALKMyVoiceCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            } else {
                height = ALKFriendVoiceCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            }
            return height.cached(with: messageModel.identifier)
        case .information:
            let height = ALKInformationCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            return height.cached(with: messageModel.identifier)
        case .location:
            return (messageModel.isMyMessage ? ALKMyLocationCell.rowHeigh(viewModel: messageModel, width: maxWidth) : ALKFriendLocationCell.rowHeigh(viewModel: messageModel, width: maxWidth)).cached(with: messageModel.identifier)
        case .video:
            var height: CGFloat =  0
            if messageModel.isMyMessage {
                height = ALKMyVideoCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            } else {
                height = ALKFriendVideoCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            }
            return height.cached(with: messageModel.identifier)
        case .genericCard, .cardTemplate:
            if messageModel.isMyMessage {
                return
                    ALKMyGenericCardCell
                    .rowHeigh(viewModel: messageModel, width: maxWidth)
                    .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendGenericCardCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
                        .cached(with: messageModel.identifier)
            }
        case .faqTemplate:
            guard let faqMessage = messageModel.faqMessage() else { return 0 }
            if messageModel.isMyMessage {
                return SentFAQMessageCell.rowHeight(model: faqMessage).cached(with: messageModel.identifier)
            } else {
                return ReceivedFAQMessageCell.rowHeight(model: faqMessage).cached(with: messageModel.identifier)
            }
        case .quickReply:
            if messageModel.isMyMessage {
                return
                    ALKMyQuickReplyCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendQuickReplyCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: messageModel.identifier)
            }
        case .button:
            if messageModel.isMyMessage {
                return
                    ALKMyMessageButtonCell
                        .rowHeigh(viewModel: messageModel, width: UIScreen.main.bounds.width)
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendMessageButtonCell
                        .rowHeigh(viewModel: messageModel, width: UIScreen.main.bounds.width)
                        .cached(with: messageModel.identifier)
            }
        case .listTemplate:
            if messageModel.isMyMessage {
                return
                    ALKMyListTemplateCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendListTemplateCell
                    .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                    .cached(with: messageModel.identifier)
            }
        case .document:
            if messageModel.isMyMessage {
                return
                    ALKMyDocumentCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendDocumentCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                        .cached(with: messageModel.identifier)
            }
        case .contact:
            if messageModel.isMyMessage {
                return
                    ALKMyContactMessageCell
                        .rowHeight()
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendContactMessageCell
                        .rowHeight()
                        .cached(with: messageModel.identifier)
            }
        case .imageMessage:
            guard let imageMessage = messageModel.imageMessage() else { return 0 }
            if messageModel.isMyMessage {
                return
                    SentImageMessageCell
                        .rowHeight(model: imageMessage)
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ReceivedImageMessageCell
                        .rowHeight(model: imageMessage)
                        .cached(with: messageModel.identifier)
            }
        case .svSendGift:
            if messageModel.isMyMessage {
                let height = SVALKMySendGiftTableViewCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                return height.cached(with: messageModel.identifier)
            } else {
                let height = SVALKFriendSendGiftTableViewCell.rowHeigh(viewModel: messageModel, width: maxWidth, replyMessage: replyMessage)
                return height.cached(with: messageModel.identifier)
            }
        }
    }

    open func nextPage(isNextPage:Bool) {
        if isNextPage {
            self.loadLatestOpenGroupMessage()
        }else{
            self.loadEarlierOpenGroupMessage()
        }
    }

    open func getMessageTemplates() -> [ALKTemplateMessageModel]? {
        // Get the json from the root folder, parse it and map it.
        let bundle = Bundle.main
        guard let jsonPath = bundle.path(forResource: "message_template", ofType: "json")
            else {
                return nil
        }
        do {
            let fileUrl = URL(fileURLWithPath: jsonPath)
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let json = jsonResult as? Dictionary<String, Any>,
                let templates = json["templates"] as? Array<Any> {
                NSLog("Template json: ",json.description )
                var templateModels: [ALKTemplateMessageModel] = []
                for element in templates {
                    if let template = element as? [String: Any],
                        let model = ALKTemplateMessageModel(json: template) {
                        templateModels.append(model)
                    }
                }
                return templateModels
            }
        } catch let error {
            NSLog("Error while fetching template json: \(error.localizedDescription)")
            return nil
        }
        return nil
    }

    open func downloadAttachment(message: ALKMessageViewModel, view: UIView? = nil, viewController: UIViewController? = nil) {
        guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }
        /// For email attachments url is to be used directly
        if message.source == emailSourceType, let url = message.fileMetaInfo?.url {
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = view as? ALKHTTPManagerDownloadDelegate ?? viewController as? ALKHTTPManagerDownloadDelegate
            let task = ALKDownloadTask(downloadUrl: url, fileName: message.fileMetaInfo?.name)
            task.identifier = message.identifier
            task.totalBytesExpectedToDownload = message.size
            httpManager.downloadImage(task: task)
            return
        }
        ALMessageClientService().downloadImageUrl(message.fileMetaInfo?.blobKey) { (fileUrl, error) in
            guard error == nil, let fileUrl = fileUrl else {
                print("Error downloading attachment :: \(String(describing: error))")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = view as? ALKHTTPManagerDownloadDelegate ?? viewController as? ALKHTTPManagerDownloadDelegate
            let task = ALKDownloadTask(downloadUrl: fileUrl, fileName: message.fileMetaInfo?.name)
            task.identifier = message.identifier
            task.totalBytesExpectedToDownload = message.size
            httpManager.downloadAttachment(task: task)
        }
    }

    /// Received from notification and from network
    open func addMessagesToList(_ messageList: [Any], isNeedOnUnreadMessageModel:Bool = false) {
        guard let messages = messageList as? [ALMessage] else { return }
        let _loginUserId = ALUserDefaultsHandler.getUserId()
        let contactService = ALContactService()
        let messageDbService = ALMessageDBService()
        
        var filteredArray = [ALMessage]()
        var replyMessageKeys = [String]()
        var contactsNotPresent = [String]()
        for index in 0..<messages.count {
            let message = messages[index]
            //if this added message is logined account
            if let _selfID = _loginUserId, message.contactIds == _selfID && message.type != myMessage {
                message.type = myMessage
            }
            let _isDeletedMsg = message.getDeletedMessageInfo().isDeleteMessage
            let _isViolateMsg = message.isMyMessage == false && message.isViolateMessage()
            if message.getActionType().isSkipMessage() || message.isHiddenMessage() || _isViolateMsg || message.isHiddenSVMessage() {
                continue
            }
            
            //filter no need display user
            if let _displayUserIdList = self.messageDisplayWithinUserList,
                self.isDisplayMessageWithinUserListMode && !_displayUserIdList.contains(message.to) {
                continue
            }
            
            if _isDeletedMsg {
                message.message = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_message_deleted")
                    ?? "Message deleted"
            }
            
            //mark message to true if not my message
            message.status = NSNumber(integerLiteral: Int(SENT.rawValue))
            
            var _isAdded = false
            if channelKey != nil && channelKey ==  message.groupId {
                _isAdded = true
                filteredArray.append(message)
                //delegate?.updateTyingStatus(status: false, userId: message.to)
            } else if message.channelKey == nil && channelKey == nil && contactId == message.to {
                _isAdded = true
                filteredArray.append(message)
                //delegate?.updateTyingStatus(status: false, userId: message.to)
            }
            //if add into list
            if _isAdded {
                let contactId = message.to ?? ""
                if !contactService.isContactExist(contactId) {
                    contactsNotPresent.append(contactId)
                }
                if _isDeletedMsg == false {
                    if let metadata = message.metadata,
                        let key = metadata[AL_MESSAGE_REPLY_KEY] as? String {
                        replyMessageKeys.append(key)
                    }
                    if message.getAttachmentType() != nil,
                        let dbMessage = messageDbService.getMessageByKey("key", value: message.identifier) as? DB_Message,
                        dbMessage.filePath != nil {
                        alMessages[index] = messageDbService.createMessageEntity(dbMessage)
                    }
                }
            }
        }
        
        self.fetchReplyMessage(replyMessageKeys: replyMessageKeys) { (tempContactsNotPresent) in
            contactsNotPresent.append(contentsOf: tempContactsNotPresent)
            self.processContacts(contactsNotPresent, completion: {
                //check duplicte
                var _tempFilteredArray = filteredArray
                for index in 0..<filteredArray.count {
                    let message = filteredArray[index]
                    //find if not exist
                    let _foundMessageIndex = self.messageModels.contains(where: { (curMessage) -> Bool in
                        if let _curKey = curMessage.rawModel?.key ,
                            _curKey == message.key {
                            return true
                        }
                        return false
                    })
                    if _foundMessageIndex {
                        _tempFilteredArray.remove(object: message)
                    }
                }
                //if empty list
                if _tempFilteredArray.count == 0 {
                    return
                }
                filteredArray = _tempFilteredArray
                
                var sortedArray = filteredArray.filter {
                    return !self.alMessageWrapper.contains(message: $0)
                }
                if filteredArray.count > 1 {
                    sortedArray = filteredArray.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
                }
                guard !sortedArray.isEmpty else { return }
                
                //add unread message
                if self.isUnreadMessageMode == false && isNeedOnUnreadMessageModel, let _unReadMsgCreateTime:Int = sortedArray.first?.createdAtTime.intValue {
                    self.isUnreadMessageMode = true
                    //remove unreadMessageSeparator from array
                    if let _index = self.findIndexOfUnreadMessageSeparator() {
                        self.delegate?.removeMessagesAt(indexPath:IndexPath(row: 0, section: _index), closureBlock: {
                            self.removeItemAt(index: _index, item: self.unreadMessageSeparator)
                        })
                    }
                    //create new one
                    self.unreadMessageSeparator = self.getUnreadMessageSeparatorMessageObject(NSNumber(value: (_unReadMsgCreateTime - 1) ))
                    sortedArray.insert(self.unreadMessageSeparator, at: 0)
                }
                
                _ = sortedArray.map { self.alMessageWrapper.addALMessage(toMessageArray: $0) }
                self.alMessages.append(contentsOf: sortedArray)
                let models = sortedArray.map { $0.messageModel }
                self.messageModels.append(contentsOf: models)
                //        print("new messages: ", models.map { $0.message })
                
                //resort for try to fix ording problem
                self.alMessages.sort { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
                self.messageModels.sort { $0.createdAtTime?.intValue ?? 0 < $1.createdAtTime?.intValue ?? 0 }
                
                //get last unread message key
                if self.isUnreadMessageMode {
                    self.lastUnreadMessageKey = self.messageModels.last?.identifier ?? nil
                }
                
                self.delegate?.newMessagesAdded()
            })
        }
    }

    open func markConversationRead() {
        if let channelKey = channelKey {
            print("mark read1")
            ALChannelService.sharedInstance().markConversation(asRead: channelKey, withCompletion: {
                _, error in
                print("mark read")
                if let error = error {
                    NSLog("error while marking conversation read: \(error)")
                }
            })
        } else if let contactId = contactId {
            ALUserService.sharedInstance().markConversation(asRead: contactId, withCompletion: {
                _,error in
                if let error = error {
                    NSLog("error while marking conversation read: \(error)")
                }
            })
        }
    }

    open func updateGroup(groupName: String, groupImage: String, friendsAdded: [ALKFriendViewModel]) {
        if !groupName.isEmpty  || !groupImage.isEmpty {
            updateGroupInfo(groupName: groupName, groupImage: groupImage, completion: { success in
                self.updateInfo()
                guard success, !friendsAdded.isEmpty else { return }
                self.addMembersToGroup(users: friendsAdded, completion: { _ in
                    print("group addition was succesful")
                })
            })
        } else {
            updateInfo()
            guard !friendsAdded.isEmpty else { return }
            self.addMembersToGroup(users: friendsAdded, completion: { _ in
                print("group addition was succesful")
            })
        }
    }

    open func updateDeliveryReport(messageKey: String, status: Int32) {
        let mesgArray = alMessages
        guard !mesgArray.isEmpty else { return }
        let filteredList = mesgArray.filter { ($0.key != nil) ? $0.key == messageKey:false }
        if !filteredList.isEmpty {
            updateMessageStatus(filteredList: filteredList, status: status)
        } else {
            guard let mesgFromService = ALMessageService
                .getMessagefromKeyValuePair("key", andValue: messageKey),
                let objectId = mesgFromService.msgDBObjectId else { return }
            let newFilteredList = mesgArray
                .filter { ($0.msgDBObjectId != nil) ? $0.msgDBObjectId == objectId:false }
            updateMessageStatus(filteredList: newFilteredList, status: status)
        }
    }

    open func updateStatusReportForConversation(contactId: String, status: Int32) {
        guard let id = self.contactId, id == contactId else { return }
        let mesgArray = self.alMessages
        guard !mesgArray.isEmpty else { return }
        for index in 0..<mesgArray.count {
            let mesg = mesgArray[index]
            if mesg.status != nil && mesg.status != NSNumber(value: status) && mesg.sentToServer == true {
                mesg.status = status as NSNumber
                self.alMessages[index] = mesg
                self.messageModels[index] = mesg.messageModel
                delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index), needReloadTable: false)
            }
            guard index < messageModels.count else { return }
        }
    }

    open func updateSendStatus(message: ALMessage) {
        let filteredList = alMessages.filter { $0 == message }
        if let alMessage = filteredList.first, let index = alMessages.index(of: alMessage) {
            alMessage.sentToServer = true
            self.alMessages[index] = alMessage
            self.messageModels[index] = alMessage.messageModel
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index), needReloadTable: false)
        }
//        else {
//            loadMessagesFromDB()
//        }

    }

    //send message
    open func send(message: String, contentType:Int32 = ALMESSAGE_CONTENT_DEFAULT, mentionUserList:[(hashID:String, name:String)]? = nil, isOpenGroup: Bool = false, metadata: [AnyHashable : Any]?) {
        let alMessage = getMessageToPost(isTextMessage: true, contentType: contentType)
        //if user has mention some user
        if let _mUserList = mentionUserList, _mUserList.count > 0 {
            var _userDisplayList = ""
            for item in _mUserList {
                _userDisplayList += "@\(item.name) "
            }
            _userDisplayList = _userDisplayList.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            _userDisplayList += "\n"
            alMessage.message = _userDisplayList + message
        }else{
            alMessage.message = message
        }
        alMessage.metadata = self.modfiedMessageMetadata(alMessage: alMessage, metadata: metadata)
        alMessage.addMentionsUserList(mentionUserList)

        addToWrapper(message: alMessage)
        let indexPath = IndexPath(row: 0, section: messageModels.count-1)
        self.delegate?.messageSent(at: indexPath)
        //check and send
        self.checkMessageBeforeSend(messageObject: alMessage, rawMessageContent: message, mentionUserList:mentionUserList, indexPath:indexPath, isOpenGroup: isOpenGroup)
    }
    
    open func checkMessageBeforeSend(messageObject: ALMessage, rawMessageContent:String?, mentionUserList:[(hashID:String, name:String)]?, indexPath:IndexPath, isOpenGroup: Bool = false) {
        if ALKConfiguration.delegateConversationRequestInfo == nil || self.delegate?.isPassMessageContentChecking() == true {
            var _indexPath = indexPath
            if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                _indexPath.section = self.alMessages.index(of: messageObject) ?? _indexPath.section
                if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                    return
                }
            }
            self.delegate?.messageCanSent(at: _indexPath, mentionUserList: mentionUserList)
            self.sendMessageToServer(messageObject: messageObject, indexPath:_indexPath, isOpenGroup: isOpenGroup)
            return
        }
        
        ALKConfiguration.delegateConversationRequestInfo?.validateMessageBeforeSend(message: rawMessageContent, completed: { (isSuccessful, error) in
            var _indexPath = indexPath
            if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                _indexPath.section = self.alMessages.index(of: messageObject) ?? _indexPath.section
                if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                    return
                }
            }
            if error != nil {
                messageObject.setSendMessageErrorFind(value: true)
                self.messageModels[_indexPath.section] = messageObject.messageModel
                self.delegate?.updateMessageAt(indexPath: _indexPath, needReloadTable: false)
                return
            }
            self.delegate?.messageCanSent(at: _indexPath, mentionUserList: mentionUserList)
            if isSuccessful == false {
                messageObject.setViolateMessage(value: true)
            }
            self.sendMessageToServer(messageObject: messageObject, indexPath:_indexPath, isOpenGroup: isOpenGroup)
        })
    }
    
    open func sendMessageToServer(messageObject: ALMessage, indexPath:IndexPath, isOpenGroup: Bool = false) {
        //send to server
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message sent before (send(message:,isOpenGroup:,metadata:)):\(messageObject.dictionary() ?? ["nil":"nil"])")
        
        if isOpenGroup {
            let messageClientService = ALMessageClientService()
            let _tempMsgForSent = ALMessage(dictonary: messageObject.dictionary())!
            _tempMsgForSent.status = NSNumber(integerLiteral: Int(SENT.rawValue))
            messageClientService.sendMessage(_tempMsgForSent.dictionary(), withCompletionHandler: {json, error in
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message sent after (send(message:,isOpenGroup:,metadata:))):\(json ?? "nil")")
                var _indexPath = indexPath
                if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                    _indexPath.section = self.alMessages.index(of: messageObject) ?? _indexPath.section
                    if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - message sent after (send(message:,isOpenGroup:,metadata:))):index \(_indexPath.section) not correct")
                        return
                    }
                }
                guard error == nil, let json = json as? [String: Any] else {
                    messageObject.setSendMessageErrorFind(value: true)
                    self.messageModels[_indexPath.section] = messageObject.messageModel
                    self.delegate?.updateMessageAt(indexPath: _indexPath, needReloadTable: true)
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - message sent after (send(message:,isOpenGroup:,metadata:))):got error \(error?.localizedDescription ?? "nil") or json nil")
                    return
                }
                
                if let response = json["response"] as? [String: Any], let key = response["messageKey"] as? String {
                    messageObject.key = key
                    messageObject.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                    if let _createdAtTime = response["createdAt"] as? Int {
                        messageObject.createdAtTime = NSNumber(value: _createdAtTime)
                    }
                } else {
                    messageObject.status = NSNumber(integerLiteral: Int(PENDING.rawValue))
                }
                
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message sent successful (send(message:,isOpenGroup:,metadata:))):\(messageObject.dictionary() ?? ["nil":"nil"])")
                self.messageModels[_indexPath.section] = messageObject.messageModel
                //sort again
                self.alMessages.sort { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
                self.messageModels.sort { $0.createdAtTime?.intValue ?? 0 < $1.createdAtTime?.intValue ?? 0 }
                
                self.delegate?.updateMessageAt(indexPath: _indexPath, needReloadTable: true)
                return
            })
        } else {
            ALMessageService.sharedInstance().sendMessages(messageObject, withCompletion: { message, error in
                NSLog("Message sent section: \(indexPath.section), \(String(describing: messageObject.message))")
                var _indexPath = indexPath
                if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                    _indexPath.section = self.alMessages.index(of: messageObject) ?? _indexPath.section
                    if _indexPath.section < 0 || _indexPath.section >= self.messageModels.count {
                        return
                    }
                }
                guard error == nil else {
                    messageObject.setSendMessageErrorFind(value: true)
                    self.messageModels[_indexPath.section] = messageObject.messageModel
                    self.delegate?.updateMessageAt(indexPath: _indexPath, needReloadTable: true)
                    return
                }
                NSLog("No errors while sending the message")
                messageObject.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                self.messageModels[_indexPath.section] = messageObject.messageModel
                self.delegate?.updateMessageAt(indexPath: _indexPath, needReloadTable: true)
            })
        }
    }

    func modfiedMessageMetadata(alMessage : ALMessage,metadata: [AnyHashable : Any]?) -> NSMutableDictionary {

        var metaData = NSMutableDictionary()

        if alMessage.metadata != nil {
            metaData = alMessage.metadata
        }

        if let messageMetadata = metadata, !messageMetadata.isEmpty {
            metaData.addEntries(from: messageMetadata)
        }
        return metaData
    }

    open func send(photo: UIImage, metadata : [AnyHashable : Any]?) -> (ALMessage?, IndexPath?) {
        print("image is:  ", photo)
        let filePath = ALImagePickerHandler.saveImage(toDocDirectory: photo)
        print("filepath:: \(String(describing: filePath))")
        guard let path = filePath, let url = URL(string: path) else { return (nil, nil) }
        guard let alMessage = processAttachment(
            filePath: url,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_ATTACHMENT),
            metadata : metadata) else {
            return (nil, nil)
        }
        self.addToWrapper(message: alMessage)
        return (alMessage, IndexPath(row: 0, section: self.messageModels.count-1))

    }
    
    open func send(fileURL: URL, metadata : [AnyHashable : Any]?) -> (ALMessage?, IndexPath?) {
        print("file is:  ", fileURL)
        let _url:NSURL = fileURL as NSURL
        let _docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let _fileName = _url.deletingPathExtension!.lastPathComponent
        var _filePath = _docDir + String(format: "/%@.%@", _fileName, _url.pathExtension!)
        if FileManager.default.fileExists(atPath: _filePath) {
            _filePath = _docDir + String(format: "/%@_%f.%@", _fileName, Date().timeIntervalSince1970 * 1000, _url.pathExtension!)
        }
        let _encodedURLPath = _filePath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? _filePath
        let _fileData = NSData(contentsOf: fileURL)
        print("filepath:: \(String(describing: _filePath))")
        guard _fileData?.write(toFile: _filePath, atomically: false) ?? false, let url = URL(string: _encodedURLPath) else { return (nil, nil) }
        guard let alMessage = processAttachment(
            filePath: url,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_ATTACHMENT),
            metadata : metadata) else {
                return (nil, nil)
        }
        self.addToWrapper(message: alMessage)
        return (alMessage, IndexPath(row: 0, section: self.messageModels.count-1))
    }

    open func send(contact: CNContact, metadata: [AnyHashable: Any]?) {
        guard
            let path = ALVCardClass().saveContact(toDocDirectory: contact),
            let url = URL(string: path)
        else {
            print("Error while saving contact")
            return
        }
        guard let alMessage = processAttachment(
            filePath: url,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_VCARD),
            metadata: metadata) else { return }
        addToWrapper(message: alMessage)
        delegate?.messageSent(at: IndexPath(row: 0, section: self.messageModels.count-1))
        delegate?.messageCanSent(at: IndexPath(row: 0, section: self.messageModels.count-1), mentionUserList: nil)
        uploadAudio(alMessage: alMessage, indexPath: IndexPath(row: 0, section: self.messageModels.count-1))
    }

    open func send(voiceMessage: Data,metadata : [AnyHashable : Any]?) {
        print("voice data received: ", voiceMessage.count)
        let fileName = String(format: "AUD-%f.m4a", Date().timeIntervalSince1970*1000)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fullPath = documentsURL.appendingPathComponent(fileName)
        do {
            try voiceMessage.write(to: fullPath, options: .atomic)
        } catch {
            NSLog("error when saving the voice message")
        }
        guard let alMessage = processAttachment(
            filePath: fullPath,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_AUDIO),
            metadata : metadata) else { return }
        self.addToWrapper(message: alMessage)
        self.delegate?.messageSent(at:  IndexPath(row: 0, section: self.messageModels.count-1))
        self.delegate?.messageCanSent(at: IndexPath(row: 0, section: self.messageModels.count-1), mentionUserList: nil)
        self.uploadAudio(alMessage: alMessage, indexPath: IndexPath(row: 0, section: self.messageModels.count-1))

    }

    open func add(geocode: Geocode, metadata: [AnyHashable : Any]?) -> (ALMessage?, IndexPath?) {

        let latlonString = ["lat": "\(geocode.location.latitude)", "lon": "\(geocode.location.longitude)"]
        guard let jsonString = createJson(dict: latlonString) else { return (nil, nil) }
        let message = getLocationMessage(latLonString: jsonString)
        message.metadata = self.modfiedMessageMetadata(alMessage: message,metadata: metadata)
        addToWrapper(message: message)
        let indexPath = IndexPath(row: 0, section: messageModels.count-1)
        return (message, indexPath)
    }

    open func sendGeocode(message: ALMessage, indexPath: IndexPath) {
        self.send(alMessage: message) { updatedMessage in
            guard let mesg = updatedMessage else { return }
            DispatchQueue.main.async {
                print("UI updated at section: ", indexPath.section, message.isSent)
                message.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                self.alMessages[indexPath.section] = mesg
                self.messageModels[indexPath.section] = (mesg.messageModel)
                self.delegate?.updateMessageAt(indexPath: indexPath, needReloadTable: false)
            }
        }
    }

    open func sendVideo(atPath path: String, sourceType: UIImagePickerController.SourceType, metadata: [AnyHashable : Any]?) -> (ALMessage?, IndexPath?) {
        guard let url = URL(string: path) else { return (nil, nil) }
        var contentType = ALMESSAGE_CONTENT_ATTACHMENT
        if sourceType == .camera {
            contentType = ALMESSAGE_CONTENT_CAMERA_RECORDING
        }

        guard let alMessage = self.processAttachment(filePath: url, text: "", contentType: Int(contentType), isVideo: true, metadata:metadata ) else { return (nil, nil) }
        self.addToWrapper(message: alMessage)
        return (alMessage, IndexPath(row: 0, section: messageModels.count-1))
    }

    open func uploadVideo(view: UIView, indexPath: IndexPath) {
        let alMessage = alMessages[indexPath.section]

        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        var dbMessage: DB_Message?
        do {
            dbMessage = try messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message
        } catch {

        }
        dbMessage?.inProgress = 1
        dbMessage?.isUploadFailed = 0
        do {
            try alHandler?.managedObjectContext.save()
        } catch {

        }
        print("content type: ", alMessage.fileMeta.contentType)
        print("file path: ", alMessage.imageFilePath)
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr) else {
                NSLog("error sending video %@", error.debugDescription)
                return
            }
            NSLog("URL TO UPLOAD VIDEO AT PATH %@ IS %@", alMessage.imageFilePath ?? "",  url.description)
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadDelegate = view as? ALKHTTPManagerUploadDelegate
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = alMessage.identifier
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = {[weak self] responseDict, task in
                if task.uploadError == nil && task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }

    //FIXME: Remove indexpath from this call and add message id param. Currently there is an unneccessary dependency on the indexpath.
    open func uploadAttachmentCompleted(responseDict: Any?, indexPath: IndexPath) {
        // populate metadata and send message
        guard alMessages.count > indexPath.section else { return }
        let alMessage = alMessages[indexPath.section]
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        var dbMessage: DB_Message?
        do {
            dbMessage = try messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message
        } catch {
            NSLog("Message not found")
        }
        guard let dbMessagePresent = dbMessage, let message = messageService.createMessageEntity(dbMessagePresent) else { return }

        guard let fileInfo = responseDict as? [String: Any] else { return }
        if ALApplozicSettings.isS3StorageServiceEnabled() {
            message.fileMeta.populate(fileInfo)
        } else {
            guard let fileMeta = fileInfo["fileMeta"] as? [String: Any] else { return }
            message.fileMeta.populate(fileMeta)
        }
        message.status = NSNumber(integerLiteral: Int(SENT.rawValue))
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }

        self.send(alMessage: message) {
            updatedMessage in
            guard let mesg = updatedMessage else { return }
            DispatchQueue.main.async {
                NSLog("UI updated at section: \(indexPath.section), \(message.isSent)")
                self.alMessages[indexPath.section] = mesg
                self.messageModels[indexPath.section] = (mesg.messageModel)
                self.delegate?.updateMessageAt(indexPath: indexPath, needReloadTable: false)
            }
        }
    }

    open func updateMessageModelAt(indexPath: IndexPath, data: Data) {
        var message = messageForRow(indexPath: indexPath)
        message?.voiceData = data
        messageModels[indexPath.section] = message as! ALKMessageModel
        delegate?.updateMessageAt(indexPath: indexPath, needReloadTable: false)
    }
    
    open func uploadAudio(alMessage: ALMessage, indexPath: IndexPath) {
        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        var dbMessage: DB_Message?
        do {
            dbMessage = try messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message
        } catch {
            return
        }
        dbMessage?.inProgress = 1
        dbMessage?.isUploadFailed = 0
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            return
        }
        NSLog("content type: ", alMessage.fileMeta.contentType)
        NSLog("file path: ", alMessage.imageFilePath)
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr)   else { return }
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = String(format: "section: %i, row: %i", indexPath.section, indexPath.row)
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = {[weak self] responseDict, task in
                if task.uploadError == nil && task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }

    open func uploadImage(view: UIView, indexPath: IndexPath) {

        let alMessage = alMessages[indexPath.section]
        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        var dbMessage: DB_Message?
        do {
            dbMessage = try messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message
        } catch {

        }
        dbMessage?.inProgress = 1
        dbMessage?.isUploadFailed = 0
        do {
            try alHandler?.managedObjectContext.save()
        } catch {

        }
        NSLog("content type: ", alMessage.fileMeta.contentType)
        NSLog("file path: ", alMessage.imageFilePath)
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr)   else { return }
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = String(format: "section: %i, row: %i", indexPath.section, indexPath.row)
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadDelegate = view as? ALKHTTPManagerUploadDelegate
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = {[weak self] responseDict, task in
                if task.uploadError == nil && task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }
    
    open func uploadFile(view: UIView, indexPath: IndexPath) {
        
        let alMessage = alMessages[indexPath.section]
        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        var dbMessage: DB_Message?
        do {
            dbMessage = try messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message
        } catch {
            
        }
        dbMessage?.inProgress = 1
        dbMessage?.isUploadFailed = 0
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            
        }
        NSLog("content type: ", alMessage.fileMeta.contentType)
        NSLog("file path: ", alMessage.imageFilePath)
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr)   else { return }
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = String(format: "section: %i, row: %i", indexPath.section, indexPath.row)
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadDelegate = view as? ALKHTTPManagerUploadDelegate
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = {[weak self] responseDict, task in
                if task.uploadError == nil && task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }

    open func encodeVideo(videoURL: URL, completion:@escaping (_ path: String?)->Void) {

        guard let videoURL = URL(string: "file://\(videoURL.path)") else { return }

        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocumentPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(String(format: "VID-%f.MOV", Date().timeIntervalSince1970*1000))
        do {
            let data = try Data(contentsOf: videoURL)
            try data.write(to: myDocumentPath)
        } catch (let error) {
            NSLog("error: \(error)")
        }

        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = String(format: "VID-%f.mp4", Date().timeIntervalSince1970*1000)
        let filePath = documentsDirectory2.appendingPathComponent(fileName)
        deleteFile(filePath: filePath)

        let avAsset = AVURLAsset(url: myDocumentPath)

        let startDate = NSDate()

        //Create Export session
        let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)

        exportSession!.outputURL = filePath
        exportSession!.outputFileType = AVFileType.mp4
        exportSession!.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession?.timeRange = range

        exportSession!.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession!.status {
            case .failed:
                print("%@",exportSession?.error as Any)
                completion(nil)
            case .cancelled:
                print("Export canceled")
                completion(nil)
            case .completed:
                //Video conversion finished
                let endDate = NSDate()

                let time = endDate.timeIntervalSince(startDate as Date)
                print(time)
                print("Successful!")
                print(exportSession?.outputURL as Any)
                completion(exportSession?.outputURL?.path)
            default:
                break
            }
        })
    }

    /// One of the template message was selected.
    open func selected(template: ALKTemplateMessageModel,metadata: [AnyHashable : Any]?) {
        // Send message if property is set
        guard template.sendMessageOnSelection else {return}
        var text = template.text
        if let messageToSend = template.messageToSend {
            text = messageToSend
        }

        send(message: text, isOpenGroup: isOpenGroup, metadata:metadata)
    }

    open func setSelectedMessageToReply(_ message: ALKMessageViewModel) {
        selectedMessageForReply = message
    }

    open func getSelectedMessageToReply() -> ALKMessageViewModel? {
        return selectedMessageForReply
    }

    open func clearSelectedMessageToReply() {
        selectedMessageForReply = nil
    }

    open func getIndexpathFor(message: ALKMessageModel) -> IndexPath? {
        guard let index = messageModels.index(of: message)
            else {return nil}
        return IndexPath(row: 0, section: index)
    }

    open func genericTemplateFor(message: ALKMessageViewModel) -> Any? {

        guard richMessages[message.identifier] == nil else {
            return richMessages[message.identifier]
        }
        if message.messageType == .genericCard {
            return getGenericCardTemplateFor(message: message)
        } else {
            return getGenericListTemplateFor(message: message)
        }
    }

    func updateUserDetail(_ userId: String) {
        ALUserService.updateUserDetail(userId, withCompletion: {
            userDetail in
            guard let _ = userDetail else { return }
            guard
                !self.isGroup,
                userId == self.contactId,
                let contact = ALContactService().loadContact(byKey: "userId", value: userId)
                else { return }
            self.delegate?.updateDisplay(contact: contact, channel: nil)
        })
    }

    func currentConversationProfile(completion: @escaping (ALKConversationProfile?) -> Void) {
        
        if let _channel = self.channelInfo {
            completion(self.conversationProfileFrom(contact: nil, channel: _channel))
        }else if channelKey != nil {
            let channel = ALChannelService().getChannelByKey(channelKey)
            completion(self.conversationProfileFrom(contact: nil, channel: channel))
        } else if contactId != nil {
            completion(self.conversationProfileFrom(contact: nil, channel: nil))
        }
    }

    func conversationProfileFrom(contact: ALContact?, channel: ALChannel?) -> ALKConversationProfile {
        var conversationProfile = ALKConversationProfile()
        conversationProfile.name = channel?.name ?? contact?.getDisplayName() ?? ""
        conversationProfile.imageUrl = channel?.channelImageURL ?? contact?.contactImageUrl
        guard let contact = contact, channel == nil else {
            return conversationProfile
        }
        conversationProfile.isBlocked = contact.block || contact.blockBy
        conversationProfile.status = ALKConversationProfile.Status(isOnline: contact.connected, lastSeenAt: contact.lastSeenAt)
        return conversationProfile
    }
    
    // MARK: - Private Methods
    private func updateGroupInfo(
        groupName: String,
        groupImage: String,
        completion:@escaping (Bool) -> Void) {
        guard let groupId = groupKey() else { return }
        let alchanneService = ALChannelService()
        alchanneService.updateChannel(
            groupId, andNewName: groupName,
            andImageURL: groupImage,
            orClientChannelKey: nil,
            isUpdatingMetaData: false,
            metadata: nil,
            orChildKeys: nil,
            orChannelUsers: nil,
            withCompletion: {
                errorReceived in
                if let error = errorReceived {
                    print("error received while updating group info: ", error)
                    completion(false)
                } else {
                    completion(true)
                }
        })
    }

    private func fetchOpenGroupMessages(startFromTime:NSNumber? = nil, time: NSNumber? = nil, contactId: String?, channelKey: NSNumber?, maxRecord:String? = nil, isOrderByAsc:Bool = false, completion:@escaping ([ALMessage]?, _ fistItemCreateTime:NSNumber?, _ lastItemCreateTime:NSNumber?)->Void) {
        let messageListRequest = ALKSVMessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        if startFromTime != nil {
            messageListRequest.startTimeStamp = startFromTime
        }
        if time != nil {
            messageListRequest.endTimeStamp = time
        }
        messageListRequest.orderBy = isOrderByAsc ? 0 : 1
        messageListRequest.pageSize = maxRecord ?? "\(self.defaultValue_requestMessagePageSize)"
        messageListRequest.userIds = self.messageDisplayWithinUserList
        
        let _startTime = Date()
        let messageClientService = ALMessageClientService()
        messageClientService.getMessageList(forUser: messageListRequest, withCompletion: {
            messages, error, userDetailsList in
            ALKConfiguration.delegateSystemInfoRequestDelegate?.loggingAPI(type:.debug, message: "chatgroup - fetchOpenGroupMessages completed", apiName: "getMessageList", startTime: _startTime, endTime: Date())
            if let _error = error {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - fetchOpenGroupMessages - have error \(_error.localizedDescription) ")
            }
            
            guard let alMessages = messages as? [ALMessage], alMessages.count > 0 else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - fetchOpenGroupMessages - no message list")
                completion(nil, nil, nil)
                return
            }
            let _tempMessages = alMessages.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            let _firstItemTime = _tempMessages.first?.createdAtTime
            let _lastItemTime = _tempMessages.last?.createdAtTime
            let contactService = ALContactService()
            //let messageDbService = ALMessageDBService()
            
            var _resultMessages = [ALMessage]()
            var contactsNotPresent = [String]()
            var replyMessageKeys = [String]()
            for index in 0..<alMessages.count {
                let message = alMessages[index]
                
                let _isDeletedMsg = message.getDeletedMessageInfo().isDeleteMessage
                let _isViolateMsg = message.isMyMessage == false && message.isViolateMessage()
                if message.getActionType().isSkipMessage() || message.isHiddenMessage() || _isViolateMsg || message.isHiddenSVMessage() {
                    continue
                }
                
                if _isDeletedMsg {
                    message.message = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_message_deleted")
                        ?? "Message deleted"
                }
                
                message.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                
                if _isDeletedMsg == false {
                    let contactId = message.to ?? ""
                    if !contactService.isContactExist(contactId) && !contactsNotPresent.contains(contactId) {
                        contactsNotPresent.append(contactId)
                    }
                    if let metadata = message.metadata,
                        let key = metadata[AL_MESSAGE_REPLY_KEY] as? String {
                        replyMessageKeys.append(key)
                    }
                    /*
                    if message.getAttachmentType() != nil,
                        let dbMessage = messageDbService.getMessageByKey("key", value: message.identifier) as? DB_Message,
                        dbMessage.filePath != nil {
                        message = messageDbService.createMessageEntity(dbMessage)
                    }*/
                }
                //add to result list
                _resultMessages.append(message)
            }
            
            if !replyMessageKeys.isEmpty {
                self.fetchReplyMessage(replyMessageKeys: replyMessageKeys) { (tempContactsNotPresent) in
                    for _contactId in tempContactsNotPresent {
                        if !contactsNotPresent.contains(_contactId) {
                            contactsNotPresent.append(_contactId)
                        }
                    }
                    
                    self.processContacts(contactsNotPresent, completion: {
                        completion(_resultMessages, _firstItemTime, _lastItemTime)
                    })
                }
            } else {
                self.processContacts(contactsNotPresent, completion: {
                    completion(_resultMessages, _firstItemTime, _lastItemTime)
                })
            }
        })
    }
    
    private func fetchReplyMessage(replyMessageKeys:[String], completion:@escaping (_ contactsNotPresent:[String])->Void){
        let contactService = ALContactService()
        var contactsNotPresent = [String]()
        let _startTime = Date()
        if !replyMessageKeys.isEmpty {
            ALMessageService().fetchReplyMessages(NSMutableArray(array: replyMessageKeys), withCompletion: { (replyMessages) in
                ALKConfiguration.delegateSystemInfoRequestDelegate?.loggingAPI(type:.debug, message: "chatgroup - fetchReplyMessage completed", apiName: "fetchReplyMessages", startTime: _startTime, endTime: Date())
                
                guard let replyMessages = replyMessages as? [ALMessage] else {
                    completion(contactsNotPresent)
                    return
                }
                for message in replyMessages {
                    let contactId = message.to ?? ""
                    if !contactService.isContactExist(contactId) && !contactsNotPresent.contains(contactId){
                        contactsNotPresent.append(contactId)
                    }
                }
                completion(contactsNotPresent)
            })
        } else {
            completion(contactsNotPresent)
        }
    }

    private func processContacts(_ contacts: [String], completion: @escaping () -> Void) {
        if !contacts.isEmpty {
            let _startTime = Date()
            ALUserService().fetchAndupdateUserDetails(NSMutableArray(array: contacts), withCompletion: { (userDetails, _) in
                ALKConfiguration.delegateSystemInfoRequestDelegate?.loggingAPI(type:.debug, message: "chatgroup - processContacts completed", apiName: "fetchAndupdateUserDetails", startTime: _startTime, endTime: Date())
                completion()
            })
        } else {
            completion()
        }
    }

    private func addMembersToGroup(users: [ALKFriendViewModel], completion: @escaping (Bool)->Void) {
        guard let groupId = groupKey() else { return }
        let alchanneService = ALChannelService()
        let channels = NSMutableArray(object: groupId)
        let channelUsers = NSMutableArray(array: users.map { $0.friendUUID as Any })
        alchanneService.addMultipleUsers(toChannel: channels, channelUsers: channelUsers, andCompletion: {
            error in
            if error != nil {
                print("error while adding members to group")
                completion(false)
            } else {
                completion(true)
            }
        })
    }

    private func updateDbMessageWith(key: String, value: String, filePath: String) {
        let messageService = ALMessageDBService()
        messageService.updateDbMessageWith(key: key, value: value, filePath: filePath)
    }

    private func getMessageToPost(isTextMessage: Bool = false, contentType:Int32 = ALMESSAGE_CONTENT_DEFAULT) -> ALMessage {
        var alMessage = ALMessage()
        // If it's a text message then set the reply id
        //if isTextMessage { alMessage = setReplyId(message: alMessage) }
        alMessage = setReplyId(message: alMessage)

        delegate?.willSendMessage()
        alMessage.to = contactId
        alMessage.contactIds = contactId
        alMessage.message = ""
        alMessage.type = "5"
        let date = Date().timeIntervalSince1970*1000
        alMessage.createdAtTime = NSNumber(value: date)
        alMessage.sendToDevice = false
        alMessage.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
        alMessage.shared = false
        alMessage.fileMeta = nil
        alMessage.storeOnDevice = false
        alMessage.contentType = Int16(contentType)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(SOURCE_IOS)
        alMessage.conversationId = conversationId
        alMessage.groupId = channelKey
        alMessage.addAppVersionNameInMetaData()
        alMessage.addDevicePlatformInMetaData()
        return  alMessage
    }

    private func getFileMetaInfo() -> ALFileMetaInfo {
        let info = ALFileMetaInfo()
        info.blobKey = nil
        info.contentType = ""
        info.createdAtTime = nil
        info.key = nil
        info.name = ""
        info.size = ""
        info.userKey = ""
        info.thumbnailUrl = ""
        info.progressValue = 0
        return info
    }

    private func processAttachment(filePath: URL, text: String, contentType: Int, isVideo: Bool = false, metadata : [AnyHashable : Any]? ) -> ALMessage? {
        let alMessage = getMessageToPost()
        alMessage.metadata = self.modfiedMessageMetadata(alMessage: alMessage, metadata: metadata)
        alMessage.contentType = Int16(contentType)
        alMessage.fileMeta = getFileMetaInfo()
        alMessage.imageFilePath = filePath.lastPathComponent
        alMessage.fileMeta.name = String(format: "%@", filePath.lastPathComponent)
//        if let contactId = contactId {
//            alMessage.fileMeta.name = String(format: "%@-%@", contactId, filePath.lastPathComponent)
//        }
        let pathExtension = filePath.pathExtension
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue()
        let mimetype = (UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue()) as String?
        alMessage.fileMeta.contentType = mimetype
        if(contentType == ALMESSAGE_CONTENT_VCARD) {
            alMessage.fileMeta.contentType = "text/x-vcard"
        }

        guard let imageData = NSData(contentsOfFile: filePath.path) else {
            // Empty image.
            return nil
        }
        alMessage.fileMeta.size = String(format: "%lu", imageData.length)

        let dbHandler = ALDBHandler.sharedInstance()
        let messageService = ALMessageDBService()
        let messageEntity = messageService.createMessageEntityForDBInsertion(with: alMessage)
        do {
            try dbHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
            return nil
        }
        alMessage.msgDBObjectId = messageEntity?.objectID
        return alMessage
    }

    private func createJson(dict: [String: String]) -> String? {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        } catch {
            print("error creating json")
        }
        guard let data = jsonData, let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    private func getLocationMessage(latLonString: String) -> ALMessage {
        let alMessage = getMessageToPost()
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_LOCATION)
        alMessage.message = latLonString
        return alMessage
    }

    private func send(alMessage: ALMessage, completion: @escaping (ALMessage?)->Void) {
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message sent before (send(alMessage:,completion:)):\(alMessage.dictionary() ?? ["nil":"nil"])")
        
        let messageClientService = ALMessageClientService()
        let _tempMsgForSent = ALMessage(dictonary: alMessage.dictionary())!
        _tempMsgForSent.status = NSNumber(integerLiteral: Int(SENT.rawValue))
        messageClientService.sendMessage(_tempMsgForSent.dictionary()) { json, error in
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message sent after (send(alMessage:,completion:)):\(json ?? "nil")")
            guard error == nil, let json = json as? [String: Any] else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - message sent after (send(alMessage:,completion:)):got error \(error?.localizedDescription ?? "nil") or json nil")
                completion(nil)
                return
            }
            if let response = json["response"] as? [String: Any], let key = response["messageKey"] as? String {
                alMessage.key = key
                alMessage.sentToServer = true
                alMessage.inProgress = false
                alMessage.isUploadFailed = false
                alMessage.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                if let _createdAtTime = response["createdAt"] as? Int {
                    alMessage.createdAtTime = NSNumber(value: _createdAtTime)
                }
            } else {
                alMessage.status = NSNumber(integerLiteral: Int(PENDING.rawValue))
            }
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - message sent successful (send(alMessage:,completion:)):\(alMessage.dictionary() ?? ["nil":"nil"])")
            completion(alMessage)
        }
    }

    private func updateMessageStatus(filteredList: [ALMessage], status: Int32) {
        if !filteredList.isEmpty {
            let message = filteredList.first
            message?.status = status as NSNumber
            guard let model = message?.messageModel, let index = messageModels.index(of: model) else { return }
            messageModels[index] = model
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index), needReloadTable: false)
        }
    }

    private func deleteFile(filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        } catch {
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }

    private func setReplyId(message: ALMessage) -> ALMessage {
        if let replyMessage = getSelectedMessageToReply() {
            let metaData = NSMutableDictionary()
            metaData[AL_MESSAGE_REPLY_KEY] = replyMessage.identifier
            message.metadata = metaData
        }
        return message
    }

    private func updateInfo() {
        guard let groupId = groupKey() else { return }
        let channel = ALChannelService().getChannelByKey(groupId)
        self.delegate?.updateDisplay(contact: nil, channel: channel)
    }

    private func getGenericCardTemplateFor(message: ALKMessageViewModel) -> ALKGenericCardTemplate? {
        guard
            let metadata = message.metadata,
            let payload = metadata["payload"] as? String
            else { return nil}
        do {
            let cards = try JSONDecoder().decode([ALKGenericCard].self, from: payload.data)
            let cardTemplate = ALKGenericCardTemplate(cards: cards)
            richMessages[message.identifier] = cardTemplate
            return cardTemplate
        } catch(let error) {
            print("\(error)")
            return nil
        }
    }

    private func getGenericListTemplateFor(message: ALKMessageViewModel) -> [ALKGenericListTemplate]? {
        guard
            let metadata = message.metadata,
            let payload = metadata["payload"] as? String
            else { return nil}
        do {
            let cardTemplate = try JSONDecoder().decode([ALKGenericListTemplate].self, from: payload.data)
            richMessages[message.identifier] = cardTemplate
            return cardTemplate
        } catch(let error) {
            print("\(error)")
            return nil
        }
    }
}


//MARK: - stockviva fetch message
extension ALKConversationViewModel {
    
    func messageSendUnderClearAllModel(isFirstLoad:Bool = false, startProcess:@escaping ()->Void, completed:@escaping ()->Void){
        self.isLoadingAllMessage = false
        self.isLoadingEarlierMessage = false
        self.isLoadingLatestMessage = false
        
        guard self.channelKey != nil else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - messageSendUnderClearAllModel - no channel key or group id")
            completed()
            return
        }
        //clear all
        self.clearViewModel()
        //clear unread model time
        ALKSVUserDefaultsControl.shared.removeLastReadMessageInfo()
        //start process
        startProcess()
        //reload
        var _lastReadMsgTimeNumber:NSNumber? = nil
        var _dateComponent = DateComponents()
        _dateComponent.year = 10
        if let _finalDate = Calendar.current.date(byAdding: _dateComponent, to: Date()) {
            _lastReadMsgTimeNumber = NSNumber(value: ( Int(_finalDate.timeIntervalSince1970 * 1000) + 1))
        }
        //call before record
        self.delegateChatGroupLifeCycle?.didMessageLoadStart(isEarlierMessage: false, isFirstLoad: isFirstLoad)
        self.getSearchTimeBeforeOpenGroupMessage(time: _lastReadMsgTimeNumber) { (results) in
            self.delegateChatGroupLifeCycle?.didMessageLoadCompleted(isEarlierMessage: false, isFirstLoad: isFirstLoad)
            var _resultSet:[ALMessage] = []
            if let _results = results {
                _resultSet.append(contentsOf: _results)
            }
            if _resultSet.count == 0 {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - messageSendUnderClearAllModel - no message list")
                completed()
                return
            }
            let sortedArray = _resultSet.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            self.alMessages = sortedArray
            self.alMessageWrapper.addObject(toMessageArray: NSMutableArray(array: sortedArray))
            let models = sortedArray.map { $0.messageModel }
            self.messageModels = models
            
            if self.isFirstTime {
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false, isFocusTargetAndHighlight: false)
            } else {
                self.delegate?.messageUpdated()
            }
            completed()
        }
    }
    
    func getMessageIndex(messageId: String) -> IndexPath? {
        if let _sectionIndex = messageModels.firstIndex(where: { $0.identifier == messageId }) {
            return IndexPath(row: 0, section: _sectionIndex)
        }
        return nil
    }
    
    func removeItemAt(index:Int, item:ALMessage){
        //remove unreadMessageSeparator from array
        if self.alMessages.count > index && self.messageModels.count > index && self.alMessageWrapper.messageArray.count > index {
            self.alMessages.remove(at: index)
            self.messageModels.remove(at: index)
            self.alMessageWrapper.removeALMessage(fromMessageArray: item)
            HeightCache.shared.clearAll()
        }
    }
}

//MARK: - stockviva unread message
extension ALKConversationViewModel {
    open func loadOpenGroupMessageWithUnreadModel(isFirstLoad:Bool = false){
        if self.isLoadingAllMessage {
            return
        }
        self.isLoadingAllMessage = true
        
        guard let _chKey = self.channelKey, let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - loadOpenGroupMessageWithUnreadModel - no channel key or group id")
            self.isLoadingAllMessage = false
            return
        }
        
        let _completedBlock:( (_ resultsOfBefore:[ALMessage]?, _ resultsOfAfter:[ALMessage]?)->() ) = { resultsOfBefore , resultsOfAfter in
            var _resultSet:[ALMessage] = []
            var _indexOfUnreadMessageSeparator:Int = -1
            if let _listBefore = resultsOfBefore, _listBefore.count > 0 {
                _resultSet.append(contentsOf: _listBefore)
            }
            if let _listAfter = resultsOfAfter, _listAfter.count > 0 {
                let _sortedListAfterArray = _listAfter.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
                self.isUnreadMessageMode = true
                //update time
                let _newCreateTime:Int = _sortedListAfterArray[0].createdAtTime.intValue - 1
                self.unreadMessageSeparator = self.getUnreadMessageSeparatorMessageObject(NSNumber(value: _newCreateTime ))
                _resultSet.append(self.unreadMessageSeparator)
                _indexOfUnreadMessageSeparator = _resultSet.count
                _resultSet.append(contentsOf: _sortedListAfterArray)
            }
            
            if _resultSet.count == 0 {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadOpenGroupMessageWithUnreadModel - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: _indexOfUnreadMessageSeparator, isLoadNextPage:false, isFocusTargetAndHighlight: false)
                self.isLoadingAllMessage = false
                return
            }
            let sortedArray = _resultSet.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            self.alMessages = sortedArray
            self.alMessageWrapper.addObject(toMessageArray: NSMutableArray(array: sortedArray))
            let models = sortedArray.map { $0.messageModel }
            self.messageModels = models
            
            //get last unread message key
            if self.isUnreadMessageMode {
                self.lastUnreadMessageKey = self.messageModels.last?.identifier ?? nil
            }
            
            if self.isFirstTime {
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: _indexOfUnreadMessageSeparator, isLoadNextPage:false, isFocusTargetAndHighlight: false)
            } else {
                self.delegate?.messageUpdated()
            }
            self.isLoadingAllMessage = false
        }
        
        //fetch message
        var _lastReadMsgTimeNumber:NSNumber? = nil
        if  let _lsatReadMsgInfo = ALKSVUserDefaultsControl.shared.getLastReadMessageInfo(chatGroupId: _chatGroupId) {
            _lastReadMsgTimeNumber = NSNumber(value: _lsatReadMsgInfo.createTime)
        }
        
        self.delegateChatGroupLifeCycle?.didMessageLoadStart(isEarlierMessage: false, isFirstLoad: isFirstLoad)
        if _lastReadMsgTimeNumber == nil {
            var _dateComponent = DateComponents()
            _dateComponent.year = 10
            if let _finalDate = Calendar.current.date(byAdding: _dateComponent, to: Date()) {
                _lastReadMsgTimeNumber = NSNumber(value: ( Int(_finalDate.timeIntervalSince1970 * 1000) + 1))
            }
            //call record
            self.getSearchTimeBeforeOpenGroupMessage(time: _lastReadMsgTimeNumber) { (resultsOfBefore) in
                self.delegateChatGroupLifeCycle?.didMessageLoadCompleted(isEarlierMessage: false, isFirstLoad: isFirstLoad)
                _completedBlock(resultsOfBefore, nil)
            }
        }else{
            let _halfPageSize = self.defaultValue_requestMessageHalfPageSize
            var _isAfterDlkMsgComplete = false
            var _isBeforeDlkMsgComplete = false
            var _afterMessageList:[ALMessage]?
            var _beforeMessageList:[ALMessage]?
            
            let _msgFetchCompleted:(()->()) = {
                guard _isAfterDlkMsgComplete && _isBeforeDlkMsgComplete else {
                    return
                }
                self.delegateChatGroupLifeCycle?.didMessageLoadCompleted(isEarlierMessage: false, isFirstLoad: isFirstLoad)
                _completedBlock(_beforeMessageList, _afterMessageList)
            }
            
            self.getSearchTimeAfterOpenGroupMessage(time: _lastReadMsgTimeNumber,  pageSize:_halfPageSize) { (resultsOfAfter) in
                _isAfterDlkMsgComplete = true
                _afterMessageList = resultsOfAfter
                _msgFetchCompleted()
            }
            
            //call before record
            if let _tLastReadMsgTimeNumber = _lastReadMsgTimeNumber {
                _lastReadMsgTimeNumber = NSNumber(value: (_tLastReadMsgTimeNumber.intValue + 1))
            }
            self.getSearchTimeBeforeOpenGroupMessage(time: _lastReadMsgTimeNumber, pageSize:_halfPageSize, completed: { (resultsOfBefore) in
                _isBeforeDlkMsgComplete = true
                _beforeMessageList = resultsOfBefore
                _msgFetchCompleted()
            })
        }
    }
    
    func syncOpenGroupOneMessage(message: ALMessage, isNeedOnUnreadMessageModel:Bool) {
        guard let groupId = message.groupId,
            groupId == self.channelKey,
            !message.isMyMessage,
            message.deviceKey != ALUserDefaultsHandler.getDeviceKeyString() else {
            return
        }
        addMessagesToList([message],isNeedOnUnreadMessageModel:isNeedOnUnreadMessageModel )
    }
    
    open func syncOpenGroupMessage(isNeedOnUnreadMessageModel:Bool) {
        var time: NSNumber? = nil
        if let _lastMsgTime = self.alMessages.last?.createdAtTime {
            time = NSNumber(value: (_lastMsgTime.intValue) )
        }
        
        NSLog("last record time: \(String(describing: time))")
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - syncOpenGroupMessage - time: \(String(describing: time))")
        
        let _defaultPageSize = self.defaultValue_requestMessagePageSize
        self.delegate?.loadingStarted()
        self.getSearchTimeAfterOpenGroupMessage(time: time, pageSize:_defaultPageSize, loopingStart: {
            self.delegate?.loadingStarted()
        }) { (messageList) in//completed
            self.delegate?.loadingStop()
            guard let newMessages = messageList, newMessages.count > 0 else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - syncOpenGroupMessage - no message list")
                return
            }
            //add to message list
            self.addMessagesToList(newMessages, isNeedOnUnreadMessageModel:isNeedOnUnreadMessageModel)
        }
    }
    
    private func getSearchTimeBeforeOpenGroupMessage(time:NSNumber? = nil, pageSize:Int? = nil,
                                                    minMessageRequired:Int? = nil,
                                                    downloadedMessageList:[ALMessage]? = nil,
                                                    lastLoopGotRecord:Int = 0,
                                                    loopingStart:(()->())? = nil,
                                                    completed:@escaping ( (_ results:[ALMessage]?)->() )){
        guard let _chKey = self.channelKey else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - getSearchTimeBeforeOpenGroupMessage - no channel key or group id")
            completed(downloadedMessageList)
            return
        }
        //call before record
        let _defaultPageSize = pageSize ?? self.defaultValue_requestMessagePageSize
        let _defaultMinMessageRequired = minMessageRequired ?? self.defaultValue_minMessageRequired
        self.fetchOpenGroupMessages(time: time, contactId: self.contactId, channelKey: _chKey, maxRecord:"\(_defaultPageSize)") { (messageList, firstItemCreateTime, lastItemCreateTime) in
            guard let newMessages = messageList, newMessages.count > 0 else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - getSearchTimeBeforeOpenGroupMessage - no message list")
                //if no any record, system will try to get next 50 item, untill no any message get or any message get
                if firstItemCreateTime != nil {
                    loopingStart?()
                    self.getSearchTimeBeforeOpenGroupMessage(time: firstItemCreateTime, pageSize:pageSize, downloadedMessageList:downloadedMessageList, lastLoopGotRecord:lastLoopGotRecord, completed:completed)
                }else{
                    completed(downloadedMessageList)
                }
                return
            }
            
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - getSearchTimeBeforeOpenGroupMessage - successful list count  \(newMessages.count) ")
            var _totalMsgList:[ALMessage] = downloadedMessageList ?? []
            _totalMsgList.append(contentsOf: newMessages)
            if _totalMsgList.count < _defaultMinMessageRequired && firstItemCreateTime != nil {
                loopingStart?()
                self.getSearchTimeBeforeOpenGroupMessage(time: firstItemCreateTime, pageSize:pageSize, downloadedMessageList:_totalMsgList, lastLoopGotRecord: _totalMsgList.count, completed:completed)
                return
            }
            
            //for return
            completed(_totalMsgList)
        }
    }
    
    private func getSearchTimeAfterOpenGroupMessage(time:NSNumber? = nil, pageSize:Int? = nil,
                                                    minMessageRequired:Int? = nil,
                                                    downloadedMessageList:[ALMessage]? = nil,
                                                    lastLoopGotRecord:Int = 0,
                                                    loopingStart:(()->())? = nil,
                                                    completed:@escaping ( (_ results:[ALMessage]?)->() )){
        guard let _chKey = self.channelKey else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - getSearchTimeAfterOpenGroupMessage - no channel key or group id")
            completed(downloadedMessageList)
            return
        }
        var _startDate:Date = Date()
        var searchTime: NSNumber? = nil
        if time != nil {
            searchTime = NSNumber(value: (time!.intValue + 1) )
            _startDate = Date(timeIntervalSince1970: TimeInterval( (time!.intValue/1000) + 1))
        }
        
        //end time
        var _endTimeNumber:NSNumber? = nil
        var _dateComponent = DateComponents()
        _dateComponent.year = 10
        if let _finalDate = Calendar.current.date(byAdding: _dateComponent, to: _startDate) {
            _endTimeNumber = NSNumber(value: ( Int(_finalDate.timeIntervalSince1970 * 1000) + 1))
        }
        
        let _defaultPageSize = pageSize ?? self.defaultValue_requestMessagePageSize
        let _defaultMinMessageRequired = minMessageRequired ?? self.defaultValue_minMessageRequired
        //call before record
        self.fetchOpenGroupMessages(startFromTime: searchTime, time: _endTimeNumber, contactId: self.contactId, channelKey: _chKey, maxRecord:"\(_defaultPageSize)", isOrderByAsc:true) { (messageList, firstItemCreateTime, lastItemCreateTime) in
            guard let newMessages = messageList, newMessages.count > 0 else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - getSearchTimeAfterOpenGroupMessage - no message list")
                //if no any record, system will try to get next 50 item, untill no any message get or any message get
                if lastItemCreateTime != nil {
                    loopingStart?()
                    self.getSearchTimeAfterOpenGroupMessage(time: lastItemCreateTime, pageSize:pageSize, downloadedMessageList:downloadedMessageList, lastLoopGotRecord:lastLoopGotRecord, completed:completed)
                }else{
                    completed(downloadedMessageList)
                }
                return
            }
            
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - getSearchTimeAfterOpenGroupMessage - successful list count  \(newMessages.count) ")
            var _totalMsgList:[ALMessage] = downloadedMessageList ?? []
            _totalMsgList.append(contentsOf: newMessages)
            if _totalMsgList.count < _defaultMinMessageRequired && lastItemCreateTime != nil {
                loopingStart?()
                self.getSearchTimeAfterOpenGroupMessage(time: lastItemCreateTime, pageSize:pageSize, downloadedMessageList:_totalMsgList, lastLoopGotRecord: _totalMsgList.count, completed:completed)
                return
            }
            
            //for return
            completed(_totalMsgList)
        }
    }
    
    open func loadEarlierOpenGroupMessage() {
        if self.isLoadingEarlierMessage {
            return
        }
        self.isLoadingEarlierMessage = true
        
        self.delegateChatGroupLifeCycle?.didMessageLoadStart(isEarlierMessage: true, isFirstLoad: false)
        
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(), messageList.count > 1 {
            time = (messageList.firstObject as! ALMessage).createdAtTime
        }
        NSLog("Last time: \(String(describing: time))")
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadEarlierOpenGroupMessage - time: \(String(describing: time))")
        
        let _defaultPageSize = self.defaultValue_requestMessagePageSize
        self.delegate?.loadingStarted()
        self.getSearchTimeBeforeOpenGroupMessage(time: time, pageSize:_defaultPageSize, loopingStart: {
            self.delegate?.loadingStarted()
        }) { (messageList) in //complete
            self.delegateChatGroupLifeCycle?.didMessageLoadCompleted(isEarlierMessage: true, isFirstLoad: false)
            guard let newMessages = messageList, newMessages.count > 0  else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadEarlierOpenGroupMessage - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false, isFocusTargetAndHighlight: false)
                self.isLoadingEarlierMessage = false
                return
            }
            
            for mesg in newMessages {
                guard let msg = self.alMessages.first, let time = Double(msg.createdAtTime.stringValue) else { continue }
                if let msgTime = Double(mesg.createdAtTime.stringValue), time <= msgTime {
                    continue
                }
                self.alMessageWrapper.getUpdatedMessageArray().insert(mesg, at: 0)
                self.alMessages.insert(mesg, at: 0)
                self.messageModels.insert(mesg.messageModel, at: 0)
            }
            
            //resort for try to fix ording problem
            self.alMessages.sort { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            self.messageModels.sort { $0.createdAtTime?.intValue ?? 0 < $1.createdAtTime?.intValue ?? 0 }
            
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadEarlierOpenGroupMessage - successful list count  \(self.messageModels.count) ")
            self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false, isFocusTargetAndHighlight: false)
            self.isLoadingEarlierMessage = false
        }
    }
    
    open func loadLatestOpenGroupMessage(){
        if self.isLoadingLatestMessage {
            return
        }
        self.isLoadingLatestMessage = true

        self.delegateChatGroupLifeCycle?.didMessageLoadStart(isEarlierMessage: false, isFirstLoad: false)
        
        var time: NSNumber? = nil
        if let _lastMsgTime = self.alMessages.last?.createdAtTime {
            time = NSNumber(value: (_lastMsgTime.intValue) )
        }
        NSLog("last record time: \(String(describing: time))")
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadLateOpenGroupMessage - time: \(String(describing: time))")
        
        let _defaultPageSize = self.defaultValue_requestMessagePageSize
        self.delegate?.loadingStarted()
        self.getSearchTimeAfterOpenGroupMessage(time: time, pageSize:_defaultPageSize, loopingStart: {
            self.delegate?.loadingStarted()
        }) { (messageList) in//completed
            self.delegateChatGroupLifeCycle?.didMessageLoadCompleted(isEarlierMessage: false, isFirstLoad: false)
            
            guard let newMessages = messageList, newMessages.count > 0 else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadLateOpenGroupMessage - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false, isFocusTargetAndHighlight: false)
                self.clearUnReadMessageData()
                self.clearFocusReplyMessageMode()
                self.isLoadingLatestMessage = false
                return
            }
            
            var sortedArray = newMessages.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            //add un read message separator under reply message mode
            if self.findIndexOfUnreadMessageSeparator() ?? -1 == -1 && self.isFocusReplyMessageMode == true {
                if let _chKey = self.channelKey,
                    let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey,
                    let _lsatReadMsgInfo = ALKSVUserDefaultsControl.shared.getLastReadMessageInfo(chatGroupId: _chatGroupId),
                    let _findLastReadMessageIdex = sortedArray.firstIndex(where: { $0.identifier == _lsatReadMsgInfo.messageId }) {
                    //update time
                    let _newCreateTime:Int = _lsatReadMsgInfo.createTime + 1
                    if _findLastReadMessageIdex + 1 > 0 && _findLastReadMessageIdex + 1 < sortedArray.count {
                        self.isUnreadMessageMode = true
                        self.unreadMessageSeparator = self.getUnreadMessageSeparatorMessageObject(NSNumber(value: _newCreateTime ))
                        sortedArray.insert(self.unreadMessageSeparator, at: _findLastReadMessageIdex + 1)
                    }
                }
            }
            
            for mesg in sortedArray {
                guard let msg = self.alMessages.last, let time = Double(msg.createdAtTime.stringValue) else { continue }
                if let msgTime = Double(mesg.createdAtTime.stringValue), time >= msgTime {
                    continue
                }
                self.alMessageWrapper.getUpdatedMessageArray()?.add(mesg)
                self.alMessages.append(mesg)
                self.messageModels.append(mesg.messageModel)
            }
            
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - loadLateOpenGroupMessage - successful list count  \(self.messageModels.count) ")
            //get last unread message key
            if self.isUnreadMessageMode {
                self.lastUnreadMessageKey = self.messageModels.last?.identifier ?? nil
            }
            
            if self.isFocusReplyMessageMode {
                if messageList?.count ?? 0 < self.defaultValue_minMessageRequired {
                    self.isFocusReplyMessageMode = false
                    self.isUnreadMessageMode = false
                }
            }else{
                self.isUnreadMessageMode = messageList?.count ?? 0 >= self.defaultValue_minMessageRequired
            }
            
            
            //resort for try to fix ording problem
            self.alMessages.sort { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            self.messageModels.sort { $0.createdAtTime?.intValue ?? 0 < $1.createdAtTime?.intValue ?? 0 }
            
            self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:true, isFocusTargetAndHighlight: false)
            self.isLoadingLatestMessage = false
        }
    }
    
    func findIndexOfUnreadMessageSeparator() -> Int? {
        if let _index = self.alMessages.index(of: self.unreadMessageSeparator),
            (self.messageModels.count > _index && self.messageModels[_index].isUnReadMessageSeparator()) &&
                self.alMessageWrapper.messageArray.count > _index {
            return _index
        }
        return nil
    }
    
    func clearUnReadMessageData(isCancelTheModel:Bool = true){
        if isCancelTheModel {
            self.isUnreadMessageMode = false
        }
        self.lastUnreadMessageKey = nil
    }
    
    private func getUnreadMessageSeparatorMessageObject(_ createTime:NSNumber) -> ALMessage {
        let alMessage = ALMessage()
        alMessage.to = ""
        alMessage.contactIds = ""
        alMessage.message = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_group_unread_message_separator_title") ?? ""
        alMessage.type = "4"
        let date = Date().timeIntervalSince1970*1000
        alMessage.createdAtTime = NSNumber(value: date)
        alMessage.sendToDevice = false
        alMessage.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
        alMessage.shared = false
        alMessage.fileMeta = nil
        alMessage.storeOnDevice = false
        alMessage.contentType = Int16(ALMESSAGE_CHANNEL_NOTIFICATION)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(SOURCE_IOS)
        alMessage.conversationId = conversationId
        alMessage.groupId = channelKey
        alMessage.addIsUnreadMessageSeparatorInMetaData(true)
        alMessage.createdAtTime = createTime
        return  alMessage
    }
}

//MARK: - stockviva reply message
extension ALKConversationViewModel {
    open func reloadOpenGroupFocusReplyMessage(targetMessageInfo:(id:String, createTime:Int), isFirstLoad:Bool = false){
            self.isLoadingAllMessage = false
            self.isLoadingEarlierMessage = false
            self.isLoadingLatestMessage = false

            guard self.channelKey != nil else {
               ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - reloadOpenGroupFocusReplyMessage - no channel key or group id")
               return
            }
        
            if self.isLoadingLatestMessage {
                return
            }
            self.isLoadingLatestMessage = true
            //clear all
            self.clearViewModel(isClearUnReadMessage: false, isClearFocusReplyMessageMode:false)
            //start process
            self.delegate?.loadingStarted()
            
            //adjust target msg value
            var _targetMsgTimeValueAdjust = targetMessageInfo.createTime
            let _targetMsgTimeValueCount = "\(_targetMsgTimeValueAdjust)".count
            let _diff = 13 - _targetMsgTimeValueCount
            if _diff > 0 {
                for _ in 0 ..< _diff {
                    _targetMsgTimeValueAdjust = _targetMsgTimeValueAdjust * 10
                }
            }

            //reload
            //fetch message
            let _targetMsgId:String = targetMessageInfo.id
            var _targetMsgTimeNumber:NSNumber = NSNumber(value: _targetMsgTimeValueAdjust)
        
            let _completedBlock:( (_ resultsOfBefore:[ALMessage]?, _ resultsOfAfter:[ALMessage]?)->() ) = { resultsOfBefore , resultsOfAfter in
                self.isFocusReplyMessageMode = true
                var _indexOfReplyMessage:Int = -1
                
                var _resultSet:[ALMessage] = []
                if let _listBefore = resultsOfBefore, _listBefore.count > 0 {
                    _resultSet.append(contentsOf: _listBefore)
                }
                if let _listAfter = resultsOfAfter, _listAfter.count > 0 {
                    _resultSet.append(contentsOf: _listAfter)
                }
                
                if _resultSet.count == 0 {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - reloadOpenGroupFocusReplyMessage - no message list")
                    self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: _indexOfReplyMessage, isLoadNextPage:false, isFocusTargetAndHighlight: false)
                    self.isLoadingAllMessage = false
                    return
                }
                var sortedArray = _resultSet.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
                if let _chKey = self.channelKey,
                    let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey,
                    let _lsatReadMsgInfo = ALKSVUserDefaultsControl.shared.getLastReadMessageInfo(chatGroupId: _chatGroupId),
                    let _findLastReadMessageIdex = sortedArray.firstIndex(where: { $0.identifier == _lsatReadMsgInfo.messageId }) {
                    //update time
                    let _newCreateTime:Int = _lsatReadMsgInfo.createTime + 1
                    if _findLastReadMessageIdex + 1 > 0 && _findLastReadMessageIdex + 1 < sortedArray.count {
                        self.isUnreadMessageMode = true
                        self.unreadMessageSeparator = self.getUnreadMessageSeparatorMessageObject(NSNumber(value: _newCreateTime ))
                        sortedArray.insert(self.unreadMessageSeparator, at: _findLastReadMessageIdex + 1)
                    }
                }
                
                self.alMessages = sortedArray
                self.alMessageWrapper.addObject(toMessageArray: NSMutableArray(array: sortedArray))
                let models = sortedArray.map { $0.messageModel }
                self.messageModels = models

                //get last unread message key
                if self.isUnreadMessageMode {
                    self.lastUnreadMessageKey = self.messageModels.last?.identifier ?? nil
                }
                
                //find reply message index by message key
                _indexOfReplyMessage = models.firstIndex(where: { $0.identifier == _targetMsgId }) ?? _indexOfReplyMessage
                
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: _indexOfReplyMessage, isLoadNextPage:false, isFocusTargetAndHighlight: true)
                self.isLoadingAllMessage = false
            }
            
            let _halfPageSize = self.defaultValue_requestMessageHalfPageSize
            self.delegateChatGroupLifeCycle?.didMessageLoadStart(isEarlierMessage: false, isFirstLoad: isFirstLoad)
            //download message
            var _isAfterDlkMsgComplete = false
            var _isBeforeDlkMsgComplete = false
            var _afterMessageList:[ALMessage]?
            var _beforeMessageList:[ALMessage]?
            
            let _msgFetchCompleted:(()->()) = {
                guard _isAfterDlkMsgComplete && _isBeforeDlkMsgComplete else {
                    return
                }
                self.delegateChatGroupLifeCycle?.didMessageLoadCompleted(isEarlierMessage: false, isFirstLoad: isFirstLoad)
                _completedBlock(_beforeMessageList, _afterMessageList)
            }
            self.getSearchTimeAfterOpenGroupMessage(time: _targetMsgTimeNumber,  pageSize:_halfPageSize) { (resultsOfAfter) in
                _isAfterDlkMsgComplete = true
                _afterMessageList = resultsOfAfter
                _msgFetchCompleted()
            }
            
            //call before record
            _targetMsgTimeNumber = NSNumber(value: (_targetMsgTimeNumber.intValue + 1))
            //call before record
            self.getSearchTimeBeforeOpenGroupMessage(time: _targetMsgTimeNumber, pageSize:_halfPageSize, completed: { (resultsOfBefore) in
                _isBeforeDlkMsgComplete = true
                _beforeMessageList = resultsOfBefore
                _msgFetchCompleted()
            })
    }
    
    func addReplyMessageViewHistory(currentViewMessage:ALKMessageViewModel?, replyMessage:ALKMessageViewModel?){
        guard let _cMsg = currentViewMessage, let _rMsg = replyMessage else {
            return
        }
        //remove existed
        self.replyMessageViewHistoryList.removeAll(where: { $0.identifier == _cMsg.identifier || $0.identifier == _rMsg.identifier })
        //append to last
        self.replyMessageViewHistoryList.append(_cMsg)
        self.replyMessageViewHistoryList.append(_rMsg)
    }
    
    func getLatestReplyMessageViewHistory(afterMessage:ALKMessageViewModel?) -> ALKMessageViewModel?{
        var _result:ALKMessageViewModel?
        let _afterThatMessageTime:Int? = afterMessage?.createdAtTime?.intValue
        repeat{
            //get latest history at last
            if self.replyMessageViewHistoryList.count <= 0 {
                break
            }
            _result = self.replyMessageViewHistoryList.removeLast()
            if let _msgTime = _afterThatMessageTime,
                let _lastViewMsgTime = _result?.createdAtTime?.intValue {
                if _lastViewMsgTime >= _msgTime {
                    break
                }
            }else{
                break
            }
        }while true
        
        return _result
    }
    
    func clearFocusReplyMessageMode(isCancelTheModel:Bool = true){
        if isCancelTheModel {
            self.isFocusReplyMessageMode = false
            self.replyMessageViewHistoryList.removeAll()
        }
    }
    
}

//MARK: - stockviva show display user only (admin user only)
extension ALKConversationViewModel {
    func setDisplayMessageWithinUser(_ userIdList:[String]?){
        let _oldStatus = self.isDisplayMessageWithinUserListMode
        if let _userIdList = userIdList,  _userIdList.count > 0 {
            self.messageDisplayWithinUserList = _userIdList
            self.isDisplayMessageWithinUserListMode = true
        }else{
            self.messageDisplayWithinUserList = nil
            self.isDisplayMessageWithinUserListMode = false
        }
        
        if _oldStatus != self.isDisplayMessageWithinUserListMode {
            self.delegate?.displayMessageWithinUserListModeChanged(result: self.isDisplayMessageWithinUserListMode)
        }
    }
}

//MARK: - stockviva update message content
extension ALKConversationViewModel {
    open func updateMessageContent(updatedMessage: ALMessage, isUpdateView:Bool = true) {
        let _foundMessageIndex = self.messageModels.lastIndex { (curMessage) -> Bool in
            if let _curKey = curMessage.rawModel?.key ,
                _curKey == updatedMessage.key {
                return true
            }
            return false
        }
        
        self.updateMessageContent(index: _foundMessageIndex ?? -1, updatedMessage: updatedMessage, isUpdateView:isUpdateView)
    }
    
    private func updateMessageContent(index:Int, updatedMessage: ALMessage, isUpdateView:Bool = true) {
        let _loginUserId = ALUserDefaultsHandler.getUserId()
        //if this added message is logined account
        if let _selfID = _loginUserId, updatedMessage.contactIds == _selfID && updatedMessage.type != myMessage {
            updatedMessage.type = myMessage
        }
        let _isDeletedMsg = updatedMessage.getDeletedMessageInfo().isDeleteMessage
        let _isViolateMsg = updatedMessage.isMyMessage == false && updatedMessage.isViolateMessage()
        if updatedMessage.getActionType().isSkipMessage() || updatedMessage.isHiddenMessage() || _isViolateMsg || updatedMessage.isHiddenSVMessage() {
            return
        }
        
        if _isDeletedMsg {
            updatedMessage.message = ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_message_deleted")
                ?? "Message deleted"
        }
        
        //if cannot get from list
        guard index >= 0 && index < self.alMessages.count && self.alMessages[index].key == updatedMessage.key else {
            let _dbService = ALMessageDBService()
            _dbService.deleteMessage(byKey: updatedMessage.identifier)
            _dbService.add(updatedMessage)
            return
        }
        let alMsgObj = updatedMessage.messageModel
        self.alMessages[index] = updatedMessage
        self.alMessageWrapper.messageArray[index] = updatedMessage
        self.messageModels[index] = alMsgObj
        if isUpdateView {
            HeightCache.shared.removeHeight(for: updatedMessage.key)
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index), needReloadTable: false)
        }
    }
}

//MARK: - stockviva message static function
extension ALKConversationViewModel {
    public static func getMessageType(isDeletedMessage:Bool, fileMetaContentType:String?) -> ALKConfiguration.ConversationMessageTypeForApp {
        var _result = ALKConfiguration.ConversationMessageTypeForApp.text
        if let _contentType = fileMetaContentType, isDeletedMessage == false {
            let _alMsgType = ALMessage.getAttachmentType(contentType: _contentType)
            _result = ALKConfiguration.ConversationMessageTypeForApp.getMessageTypeString(type: _alMsgType)
        }
        return _result
    }
    
    public static func getImageMessageThumbnail(thumbnailUrl:String?, thumbnailBlobKey:String?, completed:@escaping (_ result:String?)->()) -> URLSessionDataTask? {
        guard let _thumbnailUrl = thumbnailUrl, let _thumbnailBlobKey = thumbnailBlobKey else {
            completed(nil)
            return nil
        }
        let _dataTask = ALMessageClientService().svDownloadImageThumbnailUrl(_thumbnailUrl, blobKey: _thumbnailBlobKey) { (url, error) in
            guard error == nil, let url = url else {
                completed(nil)
                return
            }
            completed(url)
        }
        return _dataTask
    }
    
    public static func getDownloadImagePathURL(messageId:String?, filename:String?) -> String? {
        guard let _messageId = messageId, let _fileName = filename,
            let _fileExtension = _fileName.components(separatedBy: ".").last else {
            return nil
        }
        let _url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var _path:String? = _url.appendingPathComponent(String(format: "%@_local.%@", _messageId, _fileExtension)).path
        var _data = NSData(contentsOfFile: _path!)
        if _data == nil {
            _path = nil
            _data = NSData(contentsOfFile: _url.appendingPathComponent(_fileName).path)
            if _data != nil {
                _path = _url.appendingPathComponent(_fileName).path
            }
        }
        return _path
    }
}

//MARK: - stockviva delete message
extension ALKConversationViewModel {
    func deleteMessagForAll(viewModel:ALKMessageViewModel, indexPath:IndexPath?, startProcess:(()->())? = nil, completed:@escaping ((_ result:Bool, _ error:Error?)->())){
        //start process
        startProcess?()
        
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - delete message - start")
        if let _delegate = self.delegateConversationChatContentAction {
            _delegate.messageRequestToDelete(messageId: viewModel.identifier, completed: { (result, error) in
                if error == nil && result {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - delete message - successful, message:\(viewModel.message ?? "")")
                    //change the cell, if deleted done
                    if  let _rawHolder = viewModel.rawModel,
                        let _objIndexPath = indexPath,
                        _objIndexPath.section >= 0 && _objIndexPath.section < self.messageModels.count &&
                            _objIndexPath.section >= 0 && _objIndexPath.section < self.alMessageWrapper.messageArray.count {
                        _rawHolder.setDeletedMessage(true)
                        self.updateMessageContent(index: _objIndexPath.section, updatedMessage: _rawHolder)
                    }
                }
                
                if let _error = error as NSError? {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - delete message - error code:\(_error.code), desc:\(_error.localizedDescription)")
                }else {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - delete message - error empty result")
                }
                completed(result, error)
            })
        }else{
            //for testing only, it run when using demo app
            ALKSVMessageAPI.deleteMessage(msgKey: viewModel.identifier, isDeleteForAll: true) { (result, error) in
                var _isSuccessful = false
                if error == nil && result?.count ?? 0 > 0 {
                    _isSuccessful = true
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.debug, message: "chatgroup - delete message (testing) - successful, message:\(viewModel.message ?? "")")
                    //change the cell, if deleted done
                    if  let _rawHolder = viewModel.rawModel,
                        let _objIndexPath = indexPath,
                        _objIndexPath.section >= 0 && _objIndexPath.section < self.messageModels.count &&
                            _objIndexPath.section >= 0 && _objIndexPath.section < self.alMessageWrapper.messageArray.count {
                        _rawHolder.setDeletedMessage(true)
                        self.updateMessageContent(index: _objIndexPath.section, updatedMessage: _rawHolder)
                    }
                }
                
                if let _error = error as NSError? {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - delete message (testing) - error result:\(result ?? ""), code:\(_error.code), desc:\(_error.localizedDescription)")
                }else if result?.count ?? 0 == 0 {
                    ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - delete message (testing) - error empty result")
                }
                completed(_isSuccessful, error)
            }
        }
    }
}


//MARK: - stockviva gift message
extension ALKConversationViewModel {
    public func sendGiftMessageToServer(fromMessageModel:ALKMessageViewModel?, message:String, giftId:String) {
        guard let fromMessage = fromMessageModel, let _fromUserHashId = fromMessage.contactId else {
            return
        }
        var _metaData:[String:Any] = [:]
        _metaData[SVALKMessageMetaDataFieldName.messageType.rawValue] = SVALKMessageType.sendGift.rawValue
        _metaData[SVALKMessageMetaDataFieldName.sendGiftInfo_GiftId.rawValue] = giftId
        _metaData[SVALKMessageMetaDataFieldName.sendGiftInfo_ReceiverHashId.rawValue] = _fromUserHashId
        self.send(message: message, mentionUserList: nil, isOpenGroup: true, metadata: _metaData)
    }
}

//MARK: - stockviva pin message
extension ALKConversationViewModel {
    public func sendSystemMessagePinMessageToServer(message:String) {
        var _metaData:[String:Any] = [:]
        _metaData[SVALKMessageMetaDataFieldName.messageType.rawValue] = SVALKMessageType.pinAlert.rawValue
        self.send(message: message, contentType:ALMESSAGE_CHANNEL_NOTIFICATION, mentionUserList: nil, isOpenGroup: true, metadata: _metaData)
    }
}
