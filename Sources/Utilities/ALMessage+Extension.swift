//
//  ALMessage+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Applozic

let friendsMessage = "4"
let myMessage = "5"

let imageBaseUrl = ALUserDefaultsHandler.getFILEURL() + "/rest/ws/aws/file/"

enum ChannelMetadataKey {
    static let conversationSubject = "KM_CONVERSATION_SUBJECT"
}

let emailSourceType = 7

extension ALMessage: ALKChatViewModelProtocol {

    private var alContact: ALContact? {
        let alContactDbService = ALContactDBService()
        guard let alContact = alContactDbService.loadContact(byKey: "userId", value: self.to) else {
            return nil
        }
        return alContact
    }

    private var alChannel: ALChannel? {
        let alChannelService = ALChannelService()

        // TODO:  This is a workaround as other method uses closure.
        // Later replace this with:
        // alChannelService.getChannelInformation(, orClientChannelKey: , withCompletion: )
        guard let alChannel = alChannelService.getChannelByKey(self.groupId) else {
            return nil
        }
        return alChannel
    }

    public var avatar: URL? {
        guard let alContact = alContact, let url = alContact.contactImageUrl else {
            return nil
        }
        return URL(string: url)
    }

    public var avatarImage: UIImage? {
        return isGroupChat ? UIImage(named: "group_profile_picture-1", in: Bundle.applozic, compatibleWith: nil) : nil
    }

    public var avatarGroupImageUrl: String? {

        guard let alChannel = alChannel, let avatar = alChannel.channelImageURL else {
            return nil
        }
        return avatar
    }

    public var name: String {
        guard let alContact = alContact, let id = alContact.userId  else {
            return ""
        }
        guard let displayName = alContact.getDisplayName(), !displayName.isEmpty else { return id }

        return displayName
    }

    public var groupName: String {
        if isGroupChat {
            guard let alChannel = alChannel, let name = alChannel.name else {
                return ""
            }
            return name
        }
        return ""
    }

    public var theLastMessage: String? {
        switch messageType {
        case .text:
            return message
        case .photo:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? "Photo"
        case .location:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_location") ?? "Location"
        case .voice:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_audio") ?? "Audio"
        case .information:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? "Update"
        case .video:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_video") ?? "Video"
        case .html:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_link") ?? "Text"
        case .genericCard:
            return message
        case .faqTemplate:
            return message ?? "FAQ"
        case .quickReply:
            return message
        case .button:
            return message
        case .listTemplate:
            return message
        case .cardTemplate:
            return message
        case .imageMessage:
            return message ?? ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_photo") ?? "Photo"
        case .email:
            guard let channelMetadata = alChannel?.metadata,
                let messageText = channelMetadata[ChannelMetadataKey.conversationSubject]
                else {
                    return message
            }
            return messageText as? String
        case .document:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_attachment") ?? "Document"
        case .contact:
            return ALKConfiguration.delegateSystemInfoRequestDelegate?.getSystemTextLocalizable(key: "chat_common_contact") ?? "Contact"
        }
    }

    public var hasUnreadMessages: Bool {
        if isGroupChat {
            guard let alChannel = alChannel, let unreadCount = alChannel.unreadCount else {
                return false
            }
            return unreadCount.boolValue
        } else {
            guard let alContact = alContact, let unreadCount = alContact.unreadCount else {
                return false
            }
            return unreadCount.boolValue
        }
    }

    var identifier: String {
        guard let key = self.key else {
            return ""
        }
        return key
    }

    var friendIdentifier: String? {
        return nil
    }

    public var totalNumberOfUnreadMessages: UInt {
        if isGroupChat {
            guard let alChannel = alChannel, let unreadCount = alChannel.unreadCount else {
                return 0
            }
            return UInt(truncating: unreadCount)
        } else {
            guard let alContact = alContact, let unreadCount = alContact.unreadCount else {
                return 0
            }
            return UInt(truncating: unreadCount)
        }

    }

    public var isGroupChat: Bool {
        guard let _ = self.groupId else {
            return false
        }
        return true
    }

    public var contactId: String? {
        return self.contactIds
    }

    public var channelKey: NSNumber? {
        return self.groupId
    }

    public var createdAt: String? {
        let isToday = ALUtilityClass.isToday(date)
        return getCreatedAtTime(isToday)
    }
}

extension ALMessage {

    var isMyMessage: Bool {
        return (type != nil) ? (type == myMessage):false
    }

    public var messageType: ALKMessageType {
        guard source != emailSourceType else {
            /// Attachments come as separate message.
            if message == nil, let type = getAttachmentType() {
                return type
            }
            return .email
        }
        
        var _conType = Int32(contentType)
        if self.getDeletedMessageInfo().isDeleteMessage {
            return .text
        }else if self.fileMeta != nil {
            _conType = ALMESSAGE_CONTENT_ATTACHMENT
        }
        switch _conType {
        case ALMESSAGE_CONTENT_DEFAULT:
            return richMessageType()
        case ALMESSAGE_CONTENT_LOCATION:
            return .location
        case ALMESSAGE_CHANNEL_NOTIFICATION:
            return .information
        case ALMESSAGE_CONTENT_TEXT_HTML:
            return .html
        case ALMESSAGE_CONTENT_VCARD:
            return .contact
        default:
            guard let attachmentType = getAttachmentType() else {return .text}
            return attachmentType
        }
    }

    var date: Date {
        guard let time = createdAtTime else { return Date() }
        let sentAt = Date(timeIntervalSince1970: Double(time.doubleValue/1000))
        return sentAt
    }

    var time: String? {

        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "HH:mm"
        return dateFormatterGet.string(from: date)
    }

    var isSent: Bool {
        guard let status = status else {
            return false
        }
        return status == NSNumber(integerLiteral: Int(SENT.rawValue))
    }

    var isAllRead: Bool {
        guard let status = status else {
            return false
        }
        return status == NSNumber(integerLiteral: Int(DELIVERED_AND_READ.rawValue))
    }

    var isAllReceived: Bool {
        guard let status = status else {
            return false
        }
        return status == NSNumber(integerLiteral: Int(DELIVERED.rawValue))
    }

    var ratio: CGFloat {
        // Using default
        if messageType == .text {
            return 1.7
        }
        return 0.9
    }

    var size: Int64 {
        guard let fileMeta = fileMeta, let size = Int64(fileMeta.size) else {
            return 0
        }
        return size
    }

    var thumbnailURL: URL? {
        guard let fileMeta = fileMeta, let urlStr = fileMeta.thumbnailUrl, let url = URL(string: urlStr)  else {
            return nil
        }
        return url
    }

    var imageUrl: URL? {
        guard let fileMeta = fileMeta, let urlStr = fileMeta.blobKey, let imageUrl = URL(string: imageBaseUrl + urlStr) else {
            return nil
        }
        return imageUrl
    }

    var filePath: String? {
        guard let filePath = imageFilePath else {
            return nil
        }
        return filePath
    }

    var geocode: Geocode? {
        guard messageType == .location else {
            return nil
        }

        // Returns lat, long
        func getCoordinates(from message: String) -> (Any, Any)? {
            guard let messageData = message.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(
                with: messageData,
                options: .mutableContainers),
                let messageJSON = jsonObject as? [String: Any] else {
                    return nil
            }
            guard let lat = messageJSON["lat"],
                let lon = messageJSON["lon"] else {
                return nil
            }
            return (lat, lon)
        }

        guard let message = message,
            let (lat, lon) = getCoordinates(from: message) else {
                return nil
        }
        // Check if type is double or string
        if let lat = lat as? Double,
            let lon = lon as? Double {
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            return Geocode(coordinates: location)
        } else {
            guard let latString = lat as? String,
                let lonString = lon as? String,
                let lat = Double(latString),
                let lon = Double(lonString) else {
                    return nil
            }
            let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            return Geocode(coordinates: location)
        }
    }

    var fileMetaInfo: ALFileMetaInfo? {
        return self.fileMeta ?? nil
    }

    func getAttachmentType() -> ALKMessageType? {
        guard let fileMeta = fileMeta else {return nil}
        if let _contentType = fileMeta.contentType {
            if _contentType.hasPrefix("image") {
                return .photo
            } else if _contentType.hasPrefix("audio") {
                return .voice
            } else if _contentType.hasPrefix("video") {
                return .video
            } else {
                return .document
            }
        }
        return .document//when content type is nil
    }
    
    private func richMessageType() -> ALKMessageType {
        guard let metadata = metadata,
            let contentType = metadata["contentType"] as? String, contentType == "300",
            let templateId = metadata["templateId"] as? String
            else {
                return .text
        }
        switch templateId {
            case "2":
                return .genericCard
            case "3":
                return .button
            case "6":
                return .quickReply
            case "7":
                return .listTemplate
            case "8":
                return .faqTemplate
            case "9":
                return .imageMessage
            case "10":
                return .cardTemplate
            default:
                return .text
        }
    }

}

extension ALMessage {

    public var messageModel: ALKMessageModel {
        let messageModel = ALKMessageModel()
        messageModel.message = message
        messageModel.isMyMessage = isMyMessage
        messageModel.identifier = identifier
        messageModel.date = date
        messageModel.time = time
        messageModel.avatarURL = avatar
        messageModel.displayName = name
        messageModel.contactId = contactId
        messageModel.conversationId = conversationId
        messageModel.channelKey = channelKey
        messageModel.isSent = isSent
        messageModel.isAllReceived = isAllReceived
        messageModel.isAllRead = isAllRead
        messageModel.messageType = messageType
        messageModel.ratio = ratio
        messageModel.size = size
        messageModel.thumbnailURL = thumbnailURL
        messageModel.imageURL = imageUrl
        messageModel.filePath = filePath
        messageModel.geocode = geocode
        messageModel.fileMetaInfo = fileMetaInfo
        messageModel.receiverId = to
        messageModel.isReplyMessage = isAReplyMessage()
        messageModel.metadata = metadata as? Dictionary<String, Any>
        messageModel.source = source
        messageModel.createdAtTime = createdAtTime
        messageModel.rawModel = self
        return messageModel
    }
}

extension ALMessage {
    override open func isEqual(_ object: Any?) -> Bool {
        if let object = object as? ALMessage, let objectKey = object.key, let key = self.key {
            return key == objectKey
        } else {
            return false
        }
    }
}

//MARK: tag stockviva
extension ALMessage {
    
    func isInvalidAttachement() -> Bool {//if file is exist, but the content type is empty to null
        guard let fileMeta = fileMeta else {return false}
        return fileMeta.contentType == nil || fileMeta.contentType.isEmpty
    }
    
    func getActionType() -> ALKMessageActionType {
        guard let metadata = self.metadata, let _action = metadata["action"] as? String else { return ALKMessageActionType.normalMessage }
        return ALKMessageActionType(rawValue: _action) ?? ALKMessageActionType.normalMessage
    }

    //system version name
    func addAppVersionNameInMetaData(){
        if let _vName = ALKConfiguration.delegateSystemInfoRequestDelegate?.getAppVersionName() {
            if self.metadata == nil {
                self.metadata = NSMutableDictionary.init()
            }
            self.metadata.setValue(_vName, forKey: SVALKMessageMetaDataFieldName.appVersionName.rawValue)
        }
    }
    
    //device platform
    func addDevicePlatformInMetaData(){
        if let _dPlatform = ALKConfiguration.delegateSystemInfoRequestDelegate?.getDevicePlatform() {
            if self.metadata == nil {
                self.metadata = NSMutableDictionary.init()
            }
            self.metadata.setValue(_dPlatform, forKey: SVALKMessageMetaDataFieldName.devicePlatform.rawValue)
        }
    }
    
    //Mentions User
    func addMentionsUserList(_ list:[(hashID:String, name:String)]?){
        //mentions
        guard let _list = list else {
            return
        }
        var _result:[[String:String]] = []
        for _item in _list {
            let _dict:[String:String] = [SVALKMessageMetaDataFieldName.userHashId.rawValue : _item.hashID]
            _result.append(_dict)
        }
        
        if let _resultStr = _result.convertToJsonString() {
            self.metadata.setValue(_resultStr, forKey: SVALKMessageMetaDataFieldName.mentions.rawValue)
        }
    }
    
    func getValueFromMetadata(_ key:SVALKMessageMetaDataFieldName) -> Any? {
        if let _metaData = self.metadata {
            return _metaData.value(forKey: key.rawValue)
        }
        return nil
    }
    
    //validate message
    func isViolateMessage() -> Bool {
        let _result = self.getValueFromMetadata(SVALKMessageMetaDataFieldName.msgViolate) as? String ?? "false" == "true"
        return _result
    }
    
    func setViolateMessage(value:Bool) {
        if self.metadata == nil {
            self.metadata = NSMutableDictionary.init()
        }
        self.metadata.setValue((value ? "true" : "false"), forKey: SVALKMessageMetaDataFieldName.msgViolate.rawValue)
    }
    
    //un read message
    func addIsUnreadMessageSeparatorInMetaData(_ isEnable:Bool){
        let _valueStr = isEnable ? "1" : "0"
        if self.metadata == nil {
            self.metadata = NSMutableDictionary.init()
        }
        self.metadata.setValue(_valueStr, forKey: SVALKMessageMetaDataFieldName.unreadMessageSeparator.rawValue)
    }
    
    //both for local key
    func isUnReadMessageSeparator() -> Bool {
        var _result = false
        if let _unreadMsgKey = self.metadata.value(forKey: SVALKMessageMetaDataFieldName.unreadMessageSeparator.rawValue) as? String, self.messageType == .information && _unreadMsgKey == "1" {
            _result = true
        }
        return _result
    }
    
    //send message error find
    func isSendMessageErrorFind() -> Bool {
        let _result = self.getValueFromMetadata(SVALKMessageMetaDataFieldName.sendMessageErrorFind) as? String ?? "false" == "true"
        return _result
    }
    
    func setSendMessageErrorFind(value:Bool) {
        if self.metadata == nil {
            self.metadata = NSMutableDictionary.init()
        }
        self.metadata.setValue((value ? "true" : "false"), forKey: SVALKMessageMetaDataFieldName.sendMessageErrorFind.rawValue)
    }
    
    //stockviva message status
    func getSVMessageStatus() -> SVALKMessageStatus {
        if self.isViolateMessage() {
            return SVALKMessageStatus.block
        } else if self.isSendMessageErrorFind() {
            return SVALKMessageStatus.error
        } else if self.isSent || self.isAllRead || self.isAllReceived || self.isMyMessage == false {
            return SVALKMessageStatus.sent
        }else {
            return SVALKMessageStatus.processing
        }
    }
    
    //delete message
    func getDeletedMessageInfo() -> (isDeleteMessage:Bool , isDeleteMessageForAll:Bool) {
        var _isDeleteMessage = false
        var _isDeleteMessageForAll = false
        if let _result = self.getValueFromMetadata(SVALKMessageMetaDataFieldName.alDeleteGroupMessageForAll) as? String {
            _isDeleteMessage = true
            _isDeleteMessageForAll = _result == "true"
        }
        return (isDeleteMessage:_isDeleteMessage , isDeleteMessageForAll:_isDeleteMessageForAll)
    }
    
    func setDeletedMessage(_ isForAll:Bool) {
        if self.metadata == nil {
            self.metadata = NSMutableDictionary.init()
        }
        self.metadata.setValue((isForAll ? "true" : "false"), forKey: SVALKMessageMetaDataFieldName.alDeleteGroupMessageForAll.rawValue)
    }
}
