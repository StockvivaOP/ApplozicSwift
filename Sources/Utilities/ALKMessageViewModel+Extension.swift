//
//  ALKMessageViewModel+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 20/05/19.
//

import Foundation

enum AttachmentState {
    case download
    case downloading(progress: Double, totalCount: Int64)
    case downloaded(filePath: String)
    case upload
    case uploading
    case uploaded
}

extension ALKMessageViewModel {

    private func messageDetails() -> Message {
        return Message(
            text: self.message,
            isMyMessage: self.isMyMessage,
            time: self.time!,
            displayName: self.displayName,
            status: self.messageStatus(),
            imageURL: self.avatarURL)
    }

    func imageMessage() -> ImageMessage? {
        let payload = self.payloadFromMetadata()
        precondition(payload != nil, "Payload cannot be nil")
        guard let imageData = payload?[0], let url = imageData["url"] as? String else {
            assertionFailure("Payload must contain url.")
            return nil
        }
        return ImageMessage(
            caption: imageData["caption"] as? String,
            url: url,
            message: messageDetails())
    }

    func faqMessage() -> FAQMessage? {
        guard
            let metadata = self.metadata,
            let payload = metadata["payload"] as? String,
            let json = try? JSONSerialization.jsonObject(with: payload.data, options : .allowFragments),
            let msg = json as? Dictionary<String,Any>
            else { return nil }

        var buttons = [String]()

        if let btns = msg["buttons"] as? [Dictionary<String,Any>] {
            btns.forEach {
                if let name = $0["name"] as? String {
                    buttons.append(name)
                }
            }
        }

        return FAQMessage(
            message: messageDetails(),
            title: msg["title"] as? String,
            description: msg["description"] as? String,
            buttonLabel: msg["buttonLabel"] as? String,
            buttons: buttons)
    }

    func messageStatus() -> MessageStatus {
        if isAllRead {
            return .read
        } else if isAllReceived {
            return .delivered
        } else if isSent {
            return .sent
        } else {
            return .pending
        }
    }

    func downloadPath() -> (String, NSData?)? {
        let url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0]
        /// Check if message is present in db.
        if let filePath = self.filePath {
            return (filePath, NSData(contentsOfFile: url.appendingPathComponent(filePath).path))
        }
        guard
            let name = fileMetaInfo?.name,
            let fileExtension = name.components(separatedBy: ".").last
            else {
                return nil
        }
        let path = String(format: "%@_local.%@", identifier, fileExtension)
        let data = NSData(contentsOfFile: url.appendingPathComponent(path).path)
        return (path, data)
    }

    func attachmentState() -> AttachmentState? {
        guard let file = downloadPath() else {
            return nil
        }
        switch isMyMessage {
        case true:
            if isSent || isAllRead || isAllReceived {
                return file.1 != nil ? .downloaded(filePath: file.0) : .download
            } else {
                return .upload
            }
        case false:
            return file.1 != nil ? .downloaded(filePath: file.0) : .download
        }
    }
}
