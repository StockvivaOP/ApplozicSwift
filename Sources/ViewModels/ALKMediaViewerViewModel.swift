//
//  ALKMediaViewerViewModel.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 28/08/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import AVFoundation
import Applozic

protocol ALKMediaViewerViewModelDelegate: class {
    func isHiddenLoadingView(_ isHidden:Bool)
    func reloadView(isDownloadAction:Bool)
}

final class ALKMediaViewerViewModel: NSObject, Localizable {

    var localizedStringFileName: String!

    private var savingImagesuccessBlock: (() -> Void)?
    private var savingImagefailBlock: ((Error) -> Void)?

    fileprivate var downloadImageSuccessBlock: (() -> Void)?
    fileprivate var downloadImageFailBlock: ((String) -> Void)?

    fileprivate lazy var loadingFailErrorMessage: String = {
        let text = localizedString(forKey: "DownloadOriginalImageFail", withDefaultValue: SystemMessage.Warning.DownloadOriginalImageFail, fileName: localizedStringFileName)
        return text
    }()

    fileprivate var messages: [ALKMessageViewModel]
    fileprivate var currentIndex: Int {
        didSet {
            delegate?.reloadView(isDownloadAction: false)
        }
    }
    fileprivate var isFirstIndexAudioVideo = false
    weak var delegate: ALKMediaViewerViewModelDelegate?

    init(messages: [ALKMessageViewModel], currentIndex: Int, localizedStringFileName: String) {
        self.localizedStringFileName = localizedStringFileName
        self.messages = messages
        self.currentIndex = currentIndex
        super.init()
        checkCurrent(index: currentIndex)
    }

    func saveImage(image: UIImage?, successBlock: @escaping () -> Void, failBlock: @escaping (Error) -> Void) {

        self.savingImagesuccessBlock   = successBlock
        self.savingImagefailBlock      = failBlock

        guard let image = image else {
            failBlock(NSError(domain: "IMAGE_NOT_AVAILABLE", code: 0 , userInfo: nil))
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, self, #selector(ALKMediaViewerViewModel.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error, let failBlock = savingImagefailBlock {
            failBlock(error)
        } else if let successBlock = savingImagesuccessBlock {
            successBlock()
        }
    }

    func getTotalCount() -> Int {
        return messages.count
    }

    func getMessageForCurrentIndex() -> ALKMessageViewModel? {
        return getMessageFor(index: currentIndex)
    }

    func getTitle() -> String {
        return "\(currentIndex+1) of \(getTotalCount())"
    }

    func updateCurrentIndex(by incr: Int) {
        let newIndex = currentIndex + incr
        guard newIndex >= 0 && newIndex < messages.count else { return }
        currentIndex = newIndex
    }

    func getURLFor(name: String) -> URL {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docDirPath.appendingPathComponent(name)
    }

    func getThumbnail(filePath: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: filePath , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            return UIImage(cgImage: cgImage)

        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

    func isAutoPlayTrueForCurrentIndex() -> Bool {
        return isFirstIndexAudioVideo
    }

    func currentIndexAudioVideoPlayed() {
        isFirstIndexAudioVideo = false
    }

    private func getMessageFor(index: Int) -> ALKMessageViewModel? {
        guard index < messages.count else { return nil}
        return messages[index]
    }

    private func checkCurrent(index: Int) {
        guard index < messages.count, (messages[currentIndex].messageType == .video || messages[currentIndex].messageType == .voice) else { return }
        isFirstIndexAudioVideo = true
    }
    
    func replaceCurrentMessage(message:ALMessage) {
        let _currentMsg = messages[currentIndex]
        let _newMsg = message.messageModel
        if _currentMsg.identifier == _newMsg.identifier {
            messages[currentIndex] = _newMsg
        }
    }
    
    func fetchMessageWithId(messageId:String, completed:@escaping ((_ message:[ALMessage]?)->())){
        ALMessageClientService().getMessagesWithkeys([messageId]) { (response, error) in
            if error != nil  || response?.status != "success"{
                completed(nil)
                return
            }
            guard let responDict = response?.response as? [AnyHashable : Any],
                let msgsDicts = responDict["message"] as? [Any] else {
                    completed(nil)
                    return
            }
            
            var _msgList:[ALMessage] = []
            for dict in msgsDicts {
                if let _msgDict = dict as? [AnyHashable : Any] {
                    let _msg:ALMessage = ALMessage(dictonary:_msgDict)
                    _msg.messageReplyType = NSNumber(value: AL_REPLY_BUT_HIDDEN.rawValue)
                    ALMessageDBService().add(_msg)
                    _msgList.append(_msg)
                }
            }
            if _msgList.count > 0 {
                completed(_msgList)
            }else{
                completed(nil)
            }
        }
    }
}

extension ALKMediaViewerViewModel : ALKHTTPManagerDownloadDelegate{
    
    func downloadImage(message: ALKMessageViewModel){
        self.delegate?.isHiddenLoadingView(false)
        ALMessageClientService().downloadImageUrl(message.fileMetaInfo?.blobKey) { (fileUrl, error) in
            guard error == nil, let _fileUrl = fileUrl else {
                print("Error downloading attachment :: \(String(describing: error))")
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKMediaViewerViewModel - downloadImage - downloadImageUrl with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), fileUrl:\(fileUrl ?? "nil"), msg_key:\(message.identifier), msg:\(message.rawModel?.dictionary() ?? ["nil":"nil"])")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: _fileUrl, fileName: message.fileMetaInfo?.name)
            task.identifier = message.identifier
            task.totalBytesExpectedToDownload = message.size
            httpManager.downloadAttachment(task: task)
        }
    }
    
    func dataDownloaded(task: ALKDownloadTask) {
        //none
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        self.delegate?.isHiddenLoadingView(true)
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKMediaViewerViewModel - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), task.filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKMediaViewerViewModel - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        if self.currentIndex >= 0  && self.currentIndex < self.messages.count {
            self.messages[self.currentIndex].filePath = filePath
        }
        DispatchQueue.main.async {
            self.delegate?.reloadView(isDownloadAction: true)
        }
    }
}
