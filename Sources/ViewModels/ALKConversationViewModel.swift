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
    func loadingFinished(error: Error?, targetFocusItemIndex:Int, isLoadNextPage:Bool)
    func messageUpdated()
    func updateMessageAt(indexPath: IndexPath)
    func removeMessagesAt(indexPath: IndexPath, closureBlock:()->Void)
    func newMessagesAdded()
    func messageSent(at: IndexPath)
    func updateDisplay(contact: ALContact?, channel: ALChannel?)
    func willSendMessage()
    func updateTyingStatus(status: Bool, userId: String)
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
    open var isContextBasedChat: Bool {
        guard conversationProxy == nil else { return true }
        guard
            let channelKey = channelKey,
            let alChannel = ALChannelService().getChannelByKey(channelKey),
            let metadata = alChannel.metadata,
            let contextBased = metadata["AL_CONTEXT_BASED_CHAT"] as? String
        else {
            return false
        }
        return contextBased.lowercased() == "true"
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

    private var shouldSendTyping: Bool = true

    private var typingTimerTask = Timer()
    
    //tag: stockviva
    private let defaultValue_requestMessagePageSize:Int = 50
    private var isLoadingLatestMessage = false
    private var unreadMessageSeparator:ALMessage = ALMessage()
    public var isUnreadMessageMode = false
    public var lastUnreadMessageKey:String? = nil
    public var delegateConversationChatContentAction:ConversationChatContentActionDelegate?

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
    public func prepareController() {

        // Load messages from server in case of open group
        guard !isOpenGroup else {
            delegate?.loadingStarted()
            self.loadOpenGroupMessageWithUnreadModel()
            return
        }

        if ALUserDefaultsHandler.isServerCallDone(forMSGList: chatId) {
            delegate?.loadingStarted()
            loadMessagesFromDB()
        } else {
            delegate?.loadingStarted()
            loadMessages()
        }
    }

    public func addToWrapper(message: ALMessage) {
        guard !alMessageWrapper.contains(message: message) else { return }
        self.alMessageWrapper.addALMessage(toMessageArray: message)
        self.alMessages.append(message)
        self.messageModels.append(message.messageModel)
    }

    func clearViewModel() {
        self.isFirstTime = true
        self.clearUnReadMessageData()
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
        switch messageModel.messageType {
        case .text, .html, .email:
            let replyMessage = replyMessageFor(message: messageModel)
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
                    let heigh = ALKMyPhotoPortalCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: messageModel.identifier)
                } else {
                    let heigh = ALKMyPhotoLandscapeCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: messageModel.identifier)
                }
            } else {
                if messageModel.ratio < 1 {
                    let heigh = ALKFriendPhotoPortalCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: messageModel.identifier)
                } else {
                    let heigh = ALKFriendPhotoLandscapeCell.rowHeigh(viewModel: messageModel, width: maxWidth)
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
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
                        .cached(with: messageModel.identifier)
            } else {
                return
                    ALKFriendDocumentCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
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
        }
    }

    open func nextPage(isNextPage:Bool) {
        guard !isOpenGroup else {
            if isNextPage {
                self.loadLateOpenGroupMessage()
            }else{
                loadEarlierMessagesForOpenGroup()
            }
            return
        }
        guard ALUserDefaultsHandler.isShowLoadEarlierOption(chatId) && ALUserDefaultsHandler.isServerCallDone(forMSGList: chatId) else {
            return
        }
        loadEarlierMessages()
    }

    open func getContextTitleData() -> ALKContextTitleDataType? {
        guard isContextBasedChat else { return nil }
        if let proxy = conversationProxy, let topicDetail = proxy.getTopicDetail() {
            return topicDetail
        } else {
            guard let metadata = ALChannelService().getChannelByKey(channelKey)?.metadata else { return nil }
            let topicDetail = ALTopicDetail()
            topicDetail.title = metadata["title"] as? String
            topicDetail.subtitle = metadata["price"] as? String
            topicDetail.link = metadata["link"] as? String
            return topicDetail
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

    /// Received from notification
    open func addMessagesToList(_ messageList: [Any], isNeedOnUnreadMessageModel:Bool = false) {
        guard let messages = messageList as? [ALMessage] else { return }
        
        let contactService = ALContactService()
        let messageDbService = ALMessageDBService()
        
        var filteredArray = [ALMessage]()
        var replyMessageKeys = [String]()
        var contactsNotPresent = [String]()
        for index in 0..<messages.count {
            let message = messages[index]
            if message.getActionType().isSkipMessage() || message.isHiddenMessage(){
                continue
            }
            
            var _isAdded = false
            if channelKey != nil && channelKey ==  message.groupId {
                _isAdded = true
                filteredArray.append(message)
                delegate?.updateTyingStatus(status: false, userId: message.to)
            } else if message.channelKey == nil && channelKey == nil && contactId == message.to {
                _isAdded = true
                filteredArray.append(message)
                delegate?.updateTyingStatus(status: false, userId: message.to)
            }
            //if add into list
            if _isAdded {
                let contactId = message.to ?? ""
                if !contactService.isContactExist(contactId) {
                    contactsNotPresent.append(contactId)
                }
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
        
        self.fetchReplyMessage(replyMessageKeys: replyMessageKeys) { (tempContactsNotPresent) in
            contactsNotPresent.append(contentsOf: tempContactsNotPresent)
            self.processContacts(contactsNotPresent, completion: {
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
                    self.unreadMessageSeparator = self.getMessageForUnreadMessageSeparator(NSNumber(value: (_unReadMsgCreateTime - 1) ))
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
                delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index))
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
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index))
        } else {
            loadMessagesFromDB()
        }

    }

    open func send(message: String, isOpenGroup: Bool = false, metadata: [AnyHashable : Any]?) {
        let alMessage = getMessageToPost(isTextMessage: true)
        alMessage.message = message
        alMessage.metadata = self.modfiedMessageMetadata(alMessage: alMessage, metadata: metadata)

        addToWrapper(message: alMessage)
        let indexPath = IndexPath(row: 0, section: messageModels.count-1)
        self.delegate?.messageSent(at: indexPath)
        if isOpenGroup {
            let messageClientService = ALMessageClientService()
            messageClientService.sendMessage(alMessage.dictionary(), withCompletionHandler: {json, error in
                guard error == nil,
                    indexPath.section < self.messageModels.count,
                    let json = json as? [String: Any]
                    else { return }
                if let response = json["response"] as? [String: Any], let key = response["messageKey"] as? String {
                    alMessage.key = key
                    alMessage.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                    if let _createdAtTime = response["createdAt"] as? Int {
                        alMessage.createdAtTime = NSNumber(value: _createdAtTime)
                    }
                } else {
                    alMessage.status = NSNumber(integerLiteral: Int(PENDING.rawValue))
                }
                self.messageModels[indexPath.section] = alMessage.messageModel
                self.delegate?.updateMessageAt(indexPath: indexPath)
                return
            })
        } else {
            ALMessageService.sharedInstance().sendMessages(alMessage, withCompletion: { message, error in
                NSLog("Message sent section: \(indexPath.section), \(String(describing: alMessage.message))")
                guard error == nil, indexPath.section < self.messageModels.count else { return }
                NSLog("No errors while sending the message")
                alMessage.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                self.messageModels[indexPath.section] = alMessage.messageModel
                self.delegate?.updateMessageAt(indexPath: indexPath)
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
                self.delegate?.updateMessageAt(indexPath: indexPath)
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
                self.delegate?.updateMessageAt(indexPath: indexPath)
            }
        }
    }

    open func updateMessageModelAt(indexPath: IndexPath, data: Data) {
        var message = messageForRow(indexPath: indexPath)
        message?.voiceData = data
        messageModels[indexPath.section] = message as! ALKMessageModel
        delegate?.updateMessageAt(indexPath: indexPath)
    }

    @objc func sendTypingStatus() {
        self.mqttObject?.sendTypingStatus(ALUserDefaultsHandler.getApplicationKey(), userID: self.contactId, andChannelKey: channelKey, typing: true)
    }

    open func sendKeyboardBeginTyping() {
        guard shouldSendTyping else { return }
        shouldSendTyping = false
        sendTypingStatus()
        typingTimerTask = Timer.scheduledTimer(timeInterval: 25.0, target: self, selector: #selector(sendTypingStatus), userInfo: nil, repeats: true)
    }

    open func sendKeyboardDoneTyping() {
        shouldSendTyping = true
        typingTimerTask.invalidate()
        self.mqttObject?.sendTypingStatus(ALUserDefaultsHandler.getApplicationKey(), userID: self.contactId, andChannelKey: channelKey, typing: false)
    }

    func syncOpenGroup(message: ALMessage) {
        guard let groupId = message.groupId,
            groupId == self.channelKey,
            !message.isMyMessage,
            message.deviceKey != ALUserDefaultsHandler.getDeviceKeyString() else {
            return
        }
        addMessagesToList([message])
    }

    open func refresh() {
        if let key = channelKey, ALChannelService.isChannelDeleted(key) {
            return
        }
        delegate?.loadingStarted()
        guard !isOpenGroup else {
            self.loadOpenGroupMessageWithUnreadModel()
            return
        }
        ALMessageService.getLatestMessage(
            forUser: ALUserDefaultsHandler.getDeviceKeyString(),
            withCompletion: { messageList, error in
                self.delegate?.loadingFinished(error: error, targetFocusItemIndex: -1, isLoadNextPage:false)
            guard error == nil,
                let messages = messageList as? [ALMessage],
                !messages.isEmpty else { return }
            self.loadMessagesFromDB()
        })
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

    open func showPoweredByMessage() -> Bool {
        return ALApplicationInfo().showPoweredByMessage()
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
        if channelKey != nil {
            ALChannelService().getChannelInformation(channelKey, orClientChannelKey: nil) { (channel) in
                guard let channel = channel else {
                    print("Error while fetching channel details")
                    completion(nil)
                    return
                }
                completion(self.conversationProfileFrom(contact: nil, channel: channel))
            }
        } else if contactId != nil {
            ALUserService().getUserDetail(contactId) { (contact) in
                guard let contact = contact else {
                    print("Error while fetching contact details")
                    completion(nil)
                    return
                }
                self.updateUserDetail(contact.userId)
                completion(self.conversationProfileFrom(contact: contact, channel: nil))
            }
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

    func loadMessages() {
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(), messageList.count > 1 {
            time = (messageList.firstObject as! ALMessage).createdAtTime
        }
        let messageListRequest = MessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        messageListRequest.endTimeStamp = time
        ALMessageService.sharedInstance().getMessageList(forUser: messageListRequest, withCompletion: {
            messages, error, _ in
            guard error == nil, let messages = messages else {
                self.delegate?.loadingFinished(error: error, targetFocusItemIndex: -1, isLoadNextPage:false)
                return
            }
            NSLog("messages loaded: ", messages)
            self.alMessages = messages.reversed() as! [ALMessage]
            self.alMessageWrapper.addObject(toMessageArray: messages)
            let models = self.alMessages.map { $0.messageModel }
            self.messageModels = models

            let showLoadEarlierOption: Bool = self.messageModels.count >= 50
            ALUserDefaultsHandler.setShowLoadEarlierOption(showLoadEarlierOption, forContactId: self.chatId)

            self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
        })
    }

    func loadMessagesFromDB(isFirstTime: Bool = true) {
        ALMessageService.getMessageList(forContactId: contactId, isGroup: isGroup, channelKey: channelKey, conversationId: conversationId, start: 0, withCompletion: {
            messages in
            guard let messages = messages else {
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
                return
            }
            NSLog("messages loaded: %@", messages)
            self.alMessages = messages as! [ALMessage]
            self.alMessageWrapper.addObject(toMessageArray: messages)
            let models = messages.map { ($0 as! ALMessage).messageModel }
            self.messageModels = models
            let showLoadEarlierOption: Bool = self.messageModels.count >= 50
            ALUserDefaultsHandler.setShowLoadEarlierOption(showLoadEarlierOption, forContactId: self.chatId)
            if isFirstTime {
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
            } else {
                self.delegate?.messageUpdated()
            }
        })
    }

    open func loadOpenGroupMessages() {
        fetchOpenGroupMessages(time: nil, contactId: contactId, channelKey: channelKey, completion: {
            messageList in
            guard let messages = messageList else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadOpenGroupMessages - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
                return
            }
            let sortedArray = messages.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            guard !sortedArray.isEmpty else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadOpenGroupMessages - cannot sort array")
                return
            }
            self.alMessages = sortedArray
            self.alMessageWrapper.addObject(toMessageArray: NSMutableArray(array: sortedArray))
            let models = sortedArray.map { $0.messageModel }
            self.messageModels = models
            if self.isFirstTime {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadOpenGroupMessages - successful with first load list count \(self.messageModels.count) ")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
            } else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadOpenGroupMessages - successful with update list count  \(self.messageModels.count) ")
                self.delegate?.messageUpdated()
            }
        })
    }

    open func loadEarlierMessagesForOpenGroup() {
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(), messageList.count > 1 {
            time = (messageList.firstObject as! ALMessage).createdAtTime
        }
        NSLog("Last time: \(String(describing: time))")
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadEarlierMessagesForOpenGroup - time: \(String(describing: time))")
        fetchOpenGroupMessages(time: time, contactId: contactId, channelKey: channelKey, completion: {
            messageList in
            guard let newMessages = messageList else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadEarlierMessagesForOpenGroup - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
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
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadEarlierMessagesForOpenGroup - successful list count  \(self.messageModels.count) ")
            self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
        })
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

    private func loadEarlierMessages() {
        self.delegate?.loadingStarted()
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(),
            messageList.count > 1,
            let first = alMessages.first {
            time = first.createdAtTime
        }
        let messageListRequest = MessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        messageListRequest.endTimeStamp = time
        ALMessageService.sharedInstance().getMessageList(forUser: messageListRequest, withCompletion: {
            messages, error, _ in
            guard error == nil, let newMessages = messages as? [ALMessage] else {
                self.delegate?.loadingFinished(error: error, targetFocusItemIndex: -1, isLoadNextPage:false)
                return
            }
            //                NSLog("messages loaded: ", messages)
            for mesg in newMessages {
                guard let msg = self.alMessages.first, let time = Double(msg.createdAtTime.stringValue) else { continue }
                if let msgTime = Double(mesg.createdAtTime.stringValue), time <= msgTime {
                    continue
                }
                self.alMessageWrapper.getUpdatedMessageArray().insert(newMessages, at: 0)
                self.alMessages.insert(mesg, at: 0)
                self.messageModels.insert(mesg.messageModel, at: 0)
            }
            if newMessages.count < 50 {
                ALUserDefaultsHandler.setShowLoadEarlierOption(false, forContactId: self.chatId)
            }
            self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
        })
    }

    private func fetchOpenGroupMessages(startFromTime:NSNumber? = nil, time: NSNumber? = nil, contactId: String?, channelKey: NSNumber?, maxRecord:String? = nil, isOrderByAsc:Bool = false, completion:@escaping ([ALMessage]?)->Void) {
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
        let messageClientService = ALMessageClientService()
        messageClientService.getMessageList(forUser: messageListRequest, withCompletion: {
            messages, error, userDetailsList in

            if let _error = error {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - fetchOpenGroupMessages - have error \(_error.localizedDescription) ")
            }
            
            let contactDbService = ALContactDBService()
            contactDbService.addUserDetails(userDetailsList)
            
            var _resultMessages = [ALMessage]()
            guard var alMessages = messages as? [ALMessage] else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - fetchOpenGroupMessages - no message list")
                completion(nil)
                return
            }
            let contactService = ALContactService()
            let messageDbService = ALMessageDBService()
            var contactsNotPresent = [String]()
            var replyMessageKeys = [String]()

            for index in 0..<alMessages.count {
                var message = alMessages[index]
                
                if message.getActionType().isSkipMessage() || message.isHiddenMessage() {
                    continue
                }
                let contactId = message.to ?? ""
                if !contactService.isContactExist(contactId) {
                    contactsNotPresent.append(contactId)
                }
                if let metadata = message.metadata,
                    let key = metadata[AL_MESSAGE_REPLY_KEY] as? String {
                    replyMessageKeys.append(key)
                }
                
                if message.getAttachmentType() != nil,
                    let dbMessage = messageDbService.getMessageByKey("key", value: message.identifier) as? DB_Message,
                    dbMessage.filePath != nil {
                    message = messageDbService.createMessageEntity(dbMessage)
                }
                //add to result list
                _resultMessages.append(message)
            }
            
            if !replyMessageKeys.isEmpty {
                ALMessageService().fetchReplyMessages(NSMutableArray(array: replyMessageKeys), withCompletion: { (replyMessages) in
                    if let replyMessages = replyMessages as? [ALMessage] {
                        for message in replyMessages {
                            let contactId = message.to ?? ""
                            if !contactService.isContactExist(contactId) {
                                contactsNotPresent.append(contactId)
                            }
                        }
                    }else{
                        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - fetchOpenGroupMessages - no reply message with key \(replyMessageKeys)")
                    }
                    self.processContacts(contactsNotPresent, completion: {
                        completion(_resultMessages)
                    })
                })
            } else {
                self.processContacts(contactsNotPresent, completion: {
                    completion(_resultMessages)
                })
            }
        })
    }
    
    private func fetchReplyMessage(replyMessageKeys:[String], completion:@escaping (_ contactsNotPresent:[String])->Void){
        let contactService = ALContactService()
        var contactsNotPresent = [String]()
        if !replyMessageKeys.isEmpty {
            ALMessageService().fetchReplyMessages(NSMutableArray(array: replyMessageKeys), withCompletion: { (replyMessages) in
                guard let replyMessages = replyMessages as? [ALMessage] else {
                    completion(contactsNotPresent)
                    return
                }
                for message in replyMessages {
                    let contactId = message.to ?? ""
                    if !contactService.isContactExist(contactId) {
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
            ALUserService().fetchAndupdateUserDetails(NSMutableArray(array: contacts), withCompletion: { (userDetails, _) in
                ALContactDBService().addUserDetails(userDetails)
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

    private func getMessageToPost(isTextMessage: Bool = false) -> ALMessage {
        var alMessage = ALMessage()
        // If it's a text message then set the reply id
        if isTextMessage { alMessage = setReplyId(message: alMessage) }

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
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(SOURCE_IOS)
        alMessage.conversationId = conversationId
        alMessage.groupId = channelKey
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
        
        let messageClientService = ALMessageClientService()
        messageClientService.sendMessage(alMessage.dictionary()) { json, error in
            guard error == nil, let json = json as? [String: Any] else {
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
            completion(alMessage)
        }
        
//        ALMessageService.sharedInstance().sendMessages(alMessage, withCompletion: {
//            message, error in
//            let newMesg = alMessage
//            NSLog("message is: ", newMesg.key)
//            NSLog("Message sent: \(String(describing: message)), \(String(describing: error))")
//            if error == nil {
//                NSLog("No errors while sending the message")
//                completion(newMesg)
//            } else {
//                completion(nil)
//            }
//        })
    }

    private func updateMessageStatus(filteredList: [ALMessage], status: Int32) {
        if !filteredList.isEmpty {
            let message = filteredList.first
            message?.status = status as NSNumber
            guard let model = message?.messageModel, let index = messageModels.index(of: model) else { return }
            messageModels[index] = model
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index))
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
    
    func messageSendUnderUnreadModel( startProcess:@escaping ()->Void, completed:@escaping ()->Void){
        guard let _chKey = self.channelKey else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - messageSendUnderUnreadModel - no channel key or group id")
            completed()
            return
        }
        startProcess()
        //clear all
        self.clearViewModel()
        //clear unread model time
        ALKSVUserDefaultsControl.shared.removeLastReadMessageTime()
        //reload
        //call before record
        self.fetchOpenGroupMessages(time: nil, contactId: self.contactId, channelKey: _chKey) { (results) in
            var _resultSet:[ALMessage] = []
            if let _results = results {
                _resultSet.append(contentsOf: _results)
            }
            if _resultSet.count == 0 {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - messageSendUnderUnreadModel - no message list")
                completed()
                return
            }
            let sortedArray = _resultSet.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            self.alMessages = sortedArray
            self.alMessageWrapper.addObject(toMessageArray: NSMutableArray(array: sortedArray))
            let models = sortedArray.map { $0.messageModel }
            self.messageModels = models
            
            if self.isFirstTime {
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
            } else {
                self.delegate?.messageUpdated()
            }
            completed()
        }
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
    open func loadOpenGroupMessageWithUnreadModel(){
        guard let _chKey = self.channelKey, let _chatGroupId = ALChannelService().getChannelByKey(_chKey)?.clientChannelKey else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadOpenGroupMessageWithUnreadModel - no channel key or group id")
            return
        }
        
        let _defaultPageSize = self.defaultValue_requestMessagePageSize
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
                self.unreadMessageSeparator = self.getMessageForUnreadMessageSeparator(NSNumber(value: _newCreateTime ))
                _resultSet.append(self.unreadMessageSeparator)
                _indexOfUnreadMessageSeparator = _resultSet.count
                _resultSet.append(contentsOf: _sortedListAfterArray)
            }
            
            if _resultSet.count == 0 {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadOpenGroupMessageWithUnreadModel - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: _indexOfUnreadMessageSeparator, isLoadNextPage:false)
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
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: _indexOfUnreadMessageSeparator, isLoadNextPage:false)
            } else {
                self.delegate?.messageUpdated()
            }
        }
        
        //fetch message
        var _lastReadMsgTimeNumber:NSNumber? = nil
        if let _lastReadMsgTime = ALKSVUserDefaultsControl.shared.getLastReadMessageTime(chatGroupId: _chatGroupId) {
            _lastReadMsgTimeNumber = NSNumber(value: (_lastReadMsgTime + 1))
        }
        if _lastReadMsgTimeNumber == nil {
            //call before record
            self.fetchOpenGroupMessages(time: nil, contactId: self.contactId, channelKey: _chKey) { (resultsOfBefore) in
                _completedBlock(resultsOfBefore, nil)
            }
        }else{
            self.fetchOpenGroupMessages(startFromTime: _lastReadMsgTimeNumber, time: nil, contactId: self.contactId, channelKey: _chKey,maxRecord:"\(_defaultPageSize)", isOrderByAsc:true) { (resultsOfAfter) in
                if _lastReadMsgTimeNumber == nil {
                    _completedBlock(resultsOfAfter, nil)
                }else {
                    //call before record
                    self.fetchOpenGroupMessages(startFromTime: nil, time: _lastReadMsgTimeNumber, contactId: self.contactId, channelKey: _chKey) { (resultsOfBefore) in
                        _completedBlock(resultsOfBefore, resultsOfAfter)
                    }
                }
            }
        }
    }
    
    open func loadLateOpenGroupMessage(){
        var time: NSNumber? = nil
        if let _lastMsgTime = self.alMessages.last?.createdAtTime {
            time = NSNumber(value: (_lastMsgTime.intValue + 1) )
        }
        
        NSLog("last record time: \(String(describing: time))")
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadLateOpenGroupMessage - time: \(String(describing: time))")
        let _defaultPageSize = self.defaultValue_requestMessagePageSize
        self.fetchOpenGroupMessages(startFromTime: time, time: nil, contactId: contactId, channelKey: channelKey, maxRecord:"\(_defaultPageSize)", isOrderByAsc:true, completion: {
            messageList in
            guard let newMessages = messageList, newMessages.count > 0 else {
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadLateOpenGroupMessage - no message list")
                self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:false)
                self.clearUnReadMessageData()
                return
            }
            
            let sortedArray = newMessages.sorted { $0.createdAtTime.intValue < $1.createdAtTime.intValue }
            for mesg in sortedArray {
                guard let msg = self.alMessages.last, let time = Double(msg.createdAtTime.stringValue) else { continue }
                if let msgTime = Double(mesg.createdAtTime.stringValue), time >= msgTime {
                    continue
                }
                self.alMessageWrapper.getUpdatedMessageArray()?.add(mesg)
                self.alMessages.append(mesg)
                self.messageModels.append(mesg.messageModel)
            }
            
            //get last unread message key
            if self.isUnreadMessageMode {
                self.lastUnreadMessageKey = self.messageModels.last?.identifier ?? nil
            }
            self.isUnreadMessageMode = messageList?.count ?? 0 >= _defaultPageSize
            
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(isDebug:true, message: "chatgroup - loadLateOpenGroupMessage - successful list count  \(self.messageModels.count) ")
            self.delegate?.loadingFinished(error: nil, targetFocusItemIndex: -1, isLoadNextPage:true)
        })
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
    
    private func getMessageForUnreadMessageSeparator(_ createTime:NSNumber) -> ALMessage {
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
