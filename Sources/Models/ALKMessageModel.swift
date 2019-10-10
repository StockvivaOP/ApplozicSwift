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
    var thumbnailURL: URL? { get }
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
    var metadata: Dictionary<String, Any>? { get }
    var source: Int16 { get }
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
    
    public func getContentTypeForPinMessage() -> ALKMessageType{
        return self.rawModel?.getAttachmentType() ?? .text
    }
    
    public func convertModelToPinMessageEncodedString() -> String? {
        guard let _rawMsgObject = self.rawModel else {
            return nil
        }
        var _result = [String:AnyObject?]()
        _result["uuid"] = String(Date().timeIntervalSince1970 * 1000) as AnyObject?
        _result["userName"] = self.displayName as AnyObject?
        _result["userIconUrl"] = self.avatarURL?.absoluteString as AnyObject?
        
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
            let jsonData = try JSONSerialization.data(withJSONObject: _result, options: .prettyPrinted)
            _resultJsonUtf8Str = String(data: jsonData, encoding: String.Encoding.utf8)!
            NSLog("\(_resultJsonUtf8Str ?? "")")
        } catch {
            print(error.localizedDescription)
        }
        return _resultJsonUtf8Str
    }
    
    public static func convertToPinMessageModel(pinMessageJson:String?) -> (uuid:String?, userName:String?, userIconUrl:String?, message:ALKMessageViewModel?)? {
        guard let _jsonStr = pinMessageJson else { return nil }
        
        var _decodeJsonDict:[String:AnyObject?]? = nil
        do {
            if let _jsonStrData = _jsonStr.data(using: .utf8) {
                _decodeJsonDict = try JSONSerialization.jsonObject(with: _jsonStrData, options : .allowFragments) as? [String:AnyObject?]
            }
        } catch {
            print(error.localizedDescription)
        }
        
        var _result:(uuid:String?, userName:String?, userIconUrl:String?, message:ALKMessageViewModel?) = (uuid:nil, userName:nil, userIconUrl:nil, message:nil)
        if let _jsonDict = _decodeJsonDict {
            _result.uuid = _jsonDict["uuid"] as? String
            _result.userName = _jsonDict["userName"] as? String
            _result.userIconUrl = _jsonDict["userIconUrl"] as? String
            if let _messageDict = _jsonDict["message"] as? [AnyHashable : Any] {
                _result.message = ALMessage(dictonary: _messageDict)?.messageModel
            }
        }
        
        if _result.uuid == nil || _result.message == nil {
            return nil
        }
        return _result
    }
}
