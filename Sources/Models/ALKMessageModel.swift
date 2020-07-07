//
//  ALKMessageModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Applozic

// MARK: - MessageType
public enum ALKMessageType: String {
    case text = "Text"
    case photo = "Photo"
    case voice = "Audio"
    case location = "Location"
    case information = "Information"
    case video = "Video"
    case html = "HTML"
    case quickReply = "QuickReply"
    case button = "Button"
    case listTemplate = "ListTemplate"
    case cardTemplate = "CardTemplate"
    case email = "Email"
    case document = "Document"
    case contact = "Contact"

    case faqTemplate = "FAQTemplate"
    @available(*, deprecated, message: "Use `cardTemplate`.")
    case genericCard = "Card"

    case imageMessage = "ImageMessage"
    //tag: stockviva
    case svSendGift = "sv_reward"
}

// MARK: - MessageActionType
public enum ALKMessageActionType: String {
    case peopleJoinGroup = "1"
    case peopleLeaveGroup = "2"
    case groupNameChanged = "5"
    case groupMetaDataChanged = "9"
    case normalMessage = ""
    
    func isSkipMessage() -> Bool {
        return self == .peopleJoinGroup || self == .peopleLeaveGroup || self == .groupNameChanged || self == .groupMetaDataChanged
    }
}

// MARK: - stockviva SVALKMessageMetaDataFieldName
public enum SVALKMessageMetaDataFieldName : String {
    case devicePlatform = "SV_PLATFORM"
    case appVersionName = "SV_VERSION_NAME"
    case msgViolate = "SV_VIOLATE"
    case mentions = "SV_MENTIONS"
    case userHashId = "userHashId"
    case hiddenMessage = "SV_HIDDEN"//for sprint 27 or later (3.13.0)
    case alDeleteGroupMessageForAll = "AL_DELETE_GROUP_MESSAGE_FOR_ALL"
    
    //for send gift message
    case messageType = "SV_MESSAGE_TYPE"
    case sendGiftInfo_GiftId = "SV_GIFT_ID"
    case sendGiftInfo_ReceiverHashId = "SV_GIFT_RECEIVER_HASHID"
    
    //will not send to server
    case imageThumbnailURL = "SV_IMAGE_THUMBNAIL_URL"
    case sendMessageErrorFind = "SV_SEND_MSG_ERROR_FIND"
    case unreadMessageSeparator = "SV_UnreadMessageSeparator"
    
    //reply msg
    case replyUserHashId = "SV_REPLY_RECEIVER_HASHID"
    
}

// MARK: - stockviva SVALKMessageType
public enum SVALKMessageType : String {
    case sendGift = "REWARD"
    case pinAlert = "PIN_UNPIN_ALERT"
}

// MARK: - stockviva SVALKMessageStatus
public enum SVALKMessageStatus: Int {
    case processing = 1
    case sent = 2
    case error = 3
    case block = 4
}

// MARK: - MessageViewModel
public protocol ALKMessageViewModel {
    var message: String? { get }
    var isMyMessage: Bool { get }
    var messageType: ALKMessageType { get }
    var identifier: String { get }
    var date: Date { get }
    var time: String? { get }
    var avatarURL: URL? { get }
    var displayName: String? { get }
    var contactId: String? { get }
    var channelKey: NSNumber? { get }
    var conversationId: NSNumber? { get }
    var isSent: Bool { get }
    var isAllReceived: Bool { get }
    var isAllRead: Bool { get }
    var ratio: CGFloat { get }
    var size: Int64 { get }
    var thumbnailURL: URL? { get set }
    var imageURL: URL? { get }
    var filePath: String? { get set }
    var geocode: Geocode? { get }
    var voiceData: Data? { get set }
    var voiceTotalDuration: CGFloat { get set }
    var voiceCurrentDuration: CGFloat { get set }
    var voiceCurrentState: ALKVoiceCellState { get set }
    var fileMetaInfo: ALFileMetaInfo? { get }
    var receiverId: String? { get }
    var isReplyMessage: Bool { get }
    var metadata: Dictionary<String, Any>? { get set }
    var source: Int16 { get }
    var createdAtTime: NSNumber? { get set }
    var rawModel: ALMessage? { get }
}

public class ALKMessageModel: ALKMessageViewModel {

    public var message: String? = ""
    public var isMyMessage: Bool = false
    public var messageType: ALKMessageType = .text
    public var identifier: String = ""
    public var date: Date = Date()
    public var time: String?
    public var avatarURL: URL?
    public var displayName: String?
    public var contactId: String?
    public var conversationId: NSNumber?
    public var channelKey: NSNumber?
    public var isSent: Bool = false
    public var isAllReceived: Bool = false
    public var isAllRead: Bool = false
    public var ratio: CGFloat = 0.0
    public var size: Int64 = 0
    public var thumbnailURL: URL?
    public var imageURL: URL?
    public var filePath: String?
    public var geocode: Geocode?
    public var voiceTotalDuration: CGFloat = 0
    public var voiceCurrentDuration: CGFloat = 0
    public var voiceCurrentState: ALKVoiceCellState = .stop
    public var voiceData: Data?
    public var fileMetaInfo: ALFileMetaInfo?
    public var receiverId: String?
    public var isReplyMessage: Bool = false
    public var metadata: Dictionary<String, Any>?
    public var source: Int16 = 0
    public var createdAtTime: NSNumber?
    public var rawModel:ALMessage?
}

extension ALKMessageModel: Equatable {
    public static func ==(lhs: ALKMessageModel, rhs: ALKMessageModel) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension ALKMessageViewModel {
    func payloadFromMetadata() -> [Dictionary<String,Any>]? {
        guard let metadata = self.metadata, let payload = metadata["payload"] as? String else { return nil }
        let data = payload.data
        let jsonArray = try? JSONSerialization.jsonObject(with: data, options : .allowFragments)
        guard let quickReplyArray = jsonArray as? [Dictionary<String,Any>] else { return nil }
        return quickReplyArray
    }
}


//MARK: tag stockviva
extension ALKMessageViewModel {
    func getMessageSenderHashId() -> String? {
        var _userHashId = self.contactId
        if self.isMyMessage {
            _userHashId = ALUserDefaultsHandler.getUserId()
        }
        return _userHashId
    }
    
    func getMessageReceiverHashId() -> String? {
        var _userHashId = self.receiverId
        if self.isMyMessage {
            _userHashId = ALUserDefaultsHandler.getUserId()
        }
        return _userHashId
    }
    
    func getActionType() -> ALKMessageActionType {
        return self.rawModel?.getActionType() ?? ALKMessageActionType.normalMessage
    }
    
    public func getMessageTypeInMetaData() -> SVALKMessageType? {
        return self.rawModel?.getMessageTypeInMetaData()
    }
    
    func isInvalidAttachement() -> Bool {
        return self.rawModel?.isInvalidAttachement() ?? false
    }
    
    //pin message
    public func getContentTypeForPinMessage() -> ALKMessageType{
        return self.rawModel?.getAttachmentType() ?? .text
    }
    
    public func convertModelToPinMessageEncodedString(myUserName:String? = nil, myUserIconUrl:String? = nil) -> String? {
        guard let _rawMsgObject = self.rawModel else {
            return nil
        }
        var _result = [String:AnyObject?]()
        _result["uuid"] = String(Date().timeIntervalSince1970 * 1000) as AnyObject?
        if self.isMyMessage {
            _result["userName"] = myUserName as AnyObject?
            _result["userIconUrl"] = myUserIconUrl as AnyObject?
        }else{
            _result["userName"] = self.displayName as AnyObject?
            _result["userIconUrl"] = self.avatarURL?.absoluteString as AnyObject?
        }
        
        var _resultMsg = [String:AnyObject?]()
        _resultMsg["type"] = _rawMsgObject.type as AnyObject?
        _resultMsg["message"] = _rawMsgObject.message as AnyObject?
        _resultMsg["contactIds"] = _rawMsgObject.contactIds as AnyObject?
        _resultMsg["contentType"] = _rawMsgObject.contentType as AnyObject?
        _resultMsg["createdAtTime"] = _rawMsgObject.createdAtTime != nil ? _rawMsgObject.createdAtTime.intValue as AnyObject? : nil as AnyObject?
        _resultMsg["delivered"] = _rawMsgObject.delivered as AnyObject?
        _resultMsg["groupId"] = _rawMsgObject.groupId != nil ? _rawMsgObject.groupId.intValue as AnyObject? : nil as AnyObject?
        _resultMsg["key"] = _rawMsgObject.key as AnyObject?
        _resultMsg["sendToDevice"] = _rawMsgObject.sendToDevice as AnyObject?
        _resultMsg["shared"] = _rawMsgObject.shared as AnyObject?
        _resultMsg["source"] = _rawMsgObject.source as AnyObject?
        _resultMsg["status"] = _rawMsgObject.status != nil ? _rawMsgObject.status.intValue as AnyObject? : nil as AnyObject?
        _resultMsg["storeOnDevice"] = _rawMsgObject.storeOnDevice as AnyObject?
        _resultMsg["to"] = _rawMsgObject.to as AnyObject?
        if _rawMsgObject.metadata != nil {
            _resultMsg["metadata"] = _rawMsgObject.metadata.allKeys.count == 0 ? nil as AnyObject? : _rawMsgObject.metadata as AnyObject?
        }else {
            _resultMsg["metadata"] = nil as AnyObject?
        }
        
        //file meta
        var _fileMeta = [String:AnyObject?]()
        if _rawMsgObject.fileMeta != nil {
            _fileMeta["blobKey"] = _rawMsgObject.fileMeta.blobKey as AnyObject?
            _fileMeta["thumbnailBlobKey"] = _rawMsgObject.fileMeta.thumbnailBlobKey as AnyObject?
            _fileMeta["contentType"] = _rawMsgObject.fileMeta.contentType as AnyObject?
            _fileMeta["createdAtTime"] = _rawMsgObject.fileMeta.createdAtTime != nil ? _rawMsgObject.fileMeta.createdAtTime.intValue as AnyObject? : nil as AnyObject?
            _fileMeta["key"] = _rawMsgObject.fileMeta.key as AnyObject?
            _fileMeta["name"] = _rawMsgObject.fileMeta.name as AnyObject?
            _fileMeta["userKey"] = _rawMsgObject.fileMeta.userKey as AnyObject?
            _fileMeta["size"] = _rawMsgObject.fileMeta.size as AnyObject?
            _fileMeta["thumbnailUrl"] = _rawMsgObject.fileMeta.thumbnailUrl as AnyObject?
            _fileMeta["url"] = _rawMsgObject.fileMeta.url as AnyObject?
            _resultMsg["fileMeta"] = _fileMeta as AnyObject?
        }else{
            _resultMsg["fileMeta"] = nil as AnyObject?
        }
        
        _result["message"] = _resultMsg as AnyObject
        
        var _resultJsonUtf8Str:String? = nil
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: _result, options: [])
            _resultJsonUtf8Str = String(data: jsonData, encoding: String.Encoding.utf8)!
            NSLog("\(_resultJsonUtf8Str ?? "")")
        } catch {
            print(error.localizedDescription)
        }
        
        //replace special character
        let _replacingStrArray = ["&" : "\\u0026"]
        for replacingStrKey in _replacingStrArray.keys {
            _resultJsonUtf8Str = _resultJsonUtf8Str?.replacingOccurrences(of: replacingStrKey, with: _replacingStrArray[replacingStrKey]!)
        }
        
        return _resultJsonUtf8Str
    }
    
    public static func convertToPinMessageModel(pinMessageJson:String?) -> SVALKPinMessageItem? {
        guard let _jsonStr = pinMessageJson else { return nil }
        
        var _decodeJsonDict:[String:AnyObject?]? = nil
        do {
            if let _jsonStrData = _jsonStr.data(using: .utf8) {
                _decodeJsonDict = try JSONSerialization.jsonObject(with: _jsonStrData, options : .allowFragments) as? [String:AnyObject?]
            }
        } catch {
            print(error.localizedDescription)
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type:.error, message: "chatgroup - pin message decode(convertToPinMessageModel) with error:\(error.localizedDescription)")
        }
        
        var _result:SVALKPinMessageItem = SVALKPinMessageItem()
        if let _jsonDict = _decodeJsonDict {
            _result.uuid = _jsonDict["uuid"] as? String
            _result.userName = _jsonDict["userName"] as? String
            _result.userIconUrl = _jsonDict["userIconUrl"] as? String
            if let _messageDict = _jsonDict["message"] as? [AnyHashable : Any] {
                _result.messageModel = ALMessage(dictonary: _messageDict)?.messageModel
            }
        }
        
        if _result.uuid == nil || _result.messageModel == nil {
            return nil
        }
        return _result
    }
    
    public static func convertValueToPinMessageModel(chatgroupId:NSNumber,
                                                     pinMsgAtTime:NSNumber?,
                                                     userName:String,
                                                     userIconUrl:String?,
                                                     msgKey:String,
                                                     message:String?,
                                                     contactIds:String,
                                                     contentType:String,
                                                     createdAtTime:NSNumber,
                                                     receiverId to:String?,
                                                     metadata:[String:Any]?,
                                                     fileMeta:(blobKey:String,thumbnailBlobKey:String?, name:String, url:String?, contentType:String, thumbnailUrl:String?, size:Int)? ) -> SVALKPinMessageItem? {
        
        let _uuid:String = msgKey + "_\(createdAtTime.int64Value)"
        let _userName:String = userName
        let _userIconUrl:String? = userIconUrl
        
        var _msgDict = [String:Any?]()
        _msgDict["type"] = 0//inbox
        _msgDict["message"] = message
        _msgDict["contactIds"] = contactIds
        _msgDict["contentType"] = contentType
        _msgDict["createdAtTime"] = createdAtTime
        _msgDict["delivered"] = true
        _msgDict["groupId"] = chatgroupId
        _msgDict["key"] = msgKey
        _msgDict["sendToDevice"] = true
        _msgDict["shared"] = true
        _msgDict["status"] = 3//sent
        _msgDict["storeOnDevice"] = true
        _msgDict["to"] = to
        _msgDict["metadata"] = metadata
        _msgDict["source"] = Int16(SOURCE_IOS)
        if let _metadata = metadata,
            let _platform = _metadata[SVALKMessageMetaDataFieldName.devicePlatform.rawValue] as? String {
            if _platform.lowercased() == "android" {
                _msgDict["source"] = Int16(2)
            }else if _platform.lowercased() == "web" {
                _msgDict["source"] = Int16(1)
            }
        }
        
        //file meta
        var _msgFileMeta = [String:Any?]()
        if let _fileMeta = fileMeta {
            _msgFileMeta["blobKey"] = _fileMeta.blobKey
            _msgFileMeta["thumbnailBlobKey"] = _fileMeta.thumbnailBlobKey
            _msgFileMeta["contentType"] = _fileMeta.contentType
            _msgFileMeta["createdAtTime"] = String(Date().timeIntervalSince1970 * 1000)
            _msgFileMeta["key"] = ""
            _msgFileMeta["name"] = _fileMeta.name
            _msgFileMeta["userKey"] = ""
            _msgFileMeta["size"] = _fileMeta.size
            _msgFileMeta["thumbnailUrl"] = _fileMeta.thumbnailUrl
            _msgFileMeta["url"] = _fileMeta.url
            _msgDict["fileMeta"] = _msgFileMeta
        }else{
            _msgDict["fileMeta"] = nil
        }
        
        var _result:SVALKPinMessageItem = SVALKPinMessageItem()
        _result.uuid = _uuid
        _result.userName = _userName
        _result.userIconUrl = _userIconUrl
        _result.createTime = pinMsgAtTime ?? createdAtTime
        _result.messageModel = ALMessage(dictonary: _msgDict as [AnyHashable : Any])?.messageModel
        
        return _result
    }
    
    //system version name
    mutating func addAppVersionNameInMetaData(){
        if let _rawModel = self.rawModel {
            _rawModel.addAppVersionNameInMetaData()
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    //system version name
    mutating func addDevicePlatformInMetaData(){
        if let _rawModel = self.rawModel {
            _rawModel.addDevicePlatformInMetaData()
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    //Mentions User
    mutating func addMentionsUserList(_ list:[(hashID:String, name:String)]?){
        if let _rawModel = self.rawModel {
            _rawModel.addMentionsUserList(list)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    func getValueFromMetadata(_ key:SVALKMessageMetaDataFieldName) -> Any? {
        return self.rawModel?.getValueFromMetadata(key)
    }
    
    //hidden message
    func isHiddenSVMessage() -> Bool {
        return self.rawModel?.isHiddenSVMessage() ?? false
    }
    
    mutating func setHiddenSVMessage(value:Bool) {
        if let _rawModel = self.rawModel {
            _rawModel.setHiddenSVMessage(value: value)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    //validate message
    func isViolateMessage() -> Bool {
        return self.rawModel?.isViolateMessage() ?? false
    }
    
    mutating func setViolateMessage(value:Bool) {
        if let _rawModel = self.rawModel {
            _rawModel.setViolateMessage(value: value)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    //un read message
    mutating func addIsUnreadMessageSeparatorInMetaData(_ isEnable:Bool){
        if let _rawModel = self.rawModel {
            _rawModel.addIsUnreadMessageSeparatorInMetaData(isEnable)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    func isUnReadMessageSeparator() -> Bool {
        return self.rawModel?.isUnReadMessageSeparator() ?? false
    }
    
    //send message error find
    func isSendMessageErrorFind() -> Bool {
        return self.rawModel?.isSendMessageErrorFind() ?? false
    }
    
    mutating func setSendMessageErrorFind(value:Bool) {
        if let _rawModel = self.rawModel {
            _rawModel.setSendMessageErrorFind(value: value)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    //stockviva message status
    func getSVMessageStatus() -> SVALKMessageStatus {
        return self.rawModel?.getSVMessageStatus() ?? SVALKMessageStatus.processing
    }
    
    //delete message
    func isAllowToDeleteMessage(_ availableDeleteSecond:Double?) -> Bool {
        guard let _availableDeleteSecond = availableDeleteSecond else {
            return self.isMyMessage && true
        }
        var _isOverMin = true
        if let _createMsgTime = self.createdAtTime?.doubleValue {
            let _createMsgDate  = Date(timeIntervalSince1970: (_createMsgTime / 1000) )
            let _diffTimeOfSecond = Date().timeIntervalSince(_createMsgDate)
            _isOverMin = _diffTimeOfSecond <= _availableDeleteSecond
        }
        return self.isMyMessage && _isOverMin
    }
    
    public func getDeletedMessageInfo() -> (isDeleteMessage:Bool , isDeleteMessageForAll:Bool) {
        return self.rawModel?.getDeletedMessageInfo() ?? (isDeleteMessage:false , isDeleteMessageForAll:false)
    }
    
    mutating func setDeletedMessage(_ isForAll:Bool) {
        if let _rawModel = self.rawModel {
            _rawModel.setDeletedMessage(isForAll)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    //save download thumbnail URL
    mutating func saveImageThumbnailURLInMetaData(url:String?){
        if let _rawModel = self.rawModel {
            _rawModel.saveImageThumbnailURLInMetaData(url:url)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    func getImageThumbnailURL() -> String? {
        return self.rawModel?.getImageThumbnailURL()
    }
    
    
    //send gift info
    func getSendGiftMessageInfo() -> (giftId:String , receiverHashId:String?)? {
        return self.rawModel?.getSendGiftMessageInfo()
    }
    
    //reply message
    mutating func setReplyMessageInfo(id:String, msgUserHashId:String) {
        if let _rawModel = self.rawModel {
            _rawModel.setReplyMessageInfo(id: id, msgUserHashId: msgUserHashId)
            self.metadata = _rawModel.metadata as? Dictionary<String, Any>
        }
    }
    
    func haveReplyMessage() -> Bool {
        return self.rawModel?.haveReplyMessage() ?? false
    }
    
    func getReplyUserHashId() -> String {
        return self.rawModel?.getReplyUserHashId() ?? ""
    }
}
