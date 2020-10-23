//
//  ALKSVMessagePhotoDownloader.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 12/5/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import Foundation
import Applozic

public protocol ALKSVMessagePhotoDownloaderDelegate: class {
    func didPhotoDownloadCanceled(messageKey:String?)
    func didPhotoDownloadProgress(progress:Double, total:Int64)
    func didPhotoDownloadFinished(messageKey:String?, path:String?, isThumbnail:Bool, error:Error?)
}

open class ALKSVMessagePhotoDownloader : NSObject {
    
    open var delegate:ALKSVMessagePhotoDownloaderDelegate?
    open var messageKey:String?
    open var photoName:String?
    open var photoSize:Int = 0
    open var photoBlobKey:String?
    open var thumbnailUrl:String?
    open var thumbnailBlobKey:String?
    
    private var isCanceled:Bool = false
    
    // MARK: - Initializer
    public override init() {
        super.init()
    }
    
    open func downloadPhoto(isThumbnail:Bool = false){
        let _blobKey:String? = isThumbnail ? self.thumbnailBlobKey : self.photoBlobKey
        guard let _messageKey = self.messageKey, let _photoBlobKey = _blobKey else {
            self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:nil, isThumbnail: isThumbnail, error:nil)
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadPhoto error with msg_key:\(self.messageKey ?? "nil"), photoBlobKey:\(_blobKey ?? "nil")")
            return
        }
        self.isCanceled = false
        
        if isThumbnail {
            if let _thumbnailUrl = self.thumbnailUrl {
                self.downloadThumbnailImage(messageKey: _messageKey, thumbnailUrl: _thumbnailUrl, thumbnailBlobKey: _photoBlobKey)
            }
        }else{
            self.downloadPhotoImage(messageKey: _messageKey, blobKey: _photoBlobKey)
        }
    }
    
    private func downloadPhotoImage(messageKey:String, blobKey:String){
        ALMessageClientService().downloadImageUrl(blobKey) { (fileUrl, error) in
            if self.isCanceled {
                self.delegate?.didPhotoDownloadCanceled(messageKey:messageKey)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadPhotoImage with canceled, fileUrl:\(fileUrl ?? "nil"), msg_key:\(messageKey), photoBlobKey:\(blobKey)")
                return
            }
            guard error == nil, let _fileUrl = fileUrl else {
                self.delegate?.didPhotoDownloadFinished(messageKey:messageKey, path:nil, isThumbnail: false, error:error)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadPhotoImage with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), fileUrl:\(fileUrl ?? "nil"), msg_key:\(messageKey), photoBlobKey:\(blobKey)")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: _fileUrl, fileName: self.photoName)
            task.identifier = messageKey
            task.totalBytesExpectedToDownload = Int64(self.photoSize)
            httpManager.downloadAttachment(task: task)
        }
    }
    
    private func downloadThumbnailImage(messageKey:String, thumbnailUrl:String, thumbnailBlobKey:String){
        ALMessageClientService().downloadImageThumbnailUrl(thumbnailUrl, blobKey: thumbnailBlobKey) { (url, error) in
            if self.isCanceled {
                self.delegate?.didPhotoDownloadCanceled(messageKey:messageKey)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadThumbnailImage with canceled, thumbnailUrl:\(thumbnailUrl), msg_key:\(messageKey), thumbnailBlobKey:\(thumbnailBlobKey)")
                return
            }
            guard error == nil, let url = url else {
                self.delegate?.didPhotoDownloadFinished(messageKey:messageKey, path:nil, isThumbnail: true, error:error)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadThumbnailImage with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), thumbnailUrl:\(thumbnailUrl), msg_key:\(messageKey), thumbnailBlobKey:\(thumbnailBlobKey)")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: url, fileName: self.photoName)
            task.identifier = ThumbnailIdentifier.addPrefix(to: messageKey)
            httpManager.downloadAttachment(task: task)
        }
    }
    
    open func cancelDownload(){
        self.isCanceled = true
    }
    
    private func updateThumbnailPath(_ key: String, filePath: String) {
        let messageKey = ThumbnailIdentifier.removePrefix(from: key)
        guard let dbMessage = ALMessageDBService().getMessageByKey("key", value: messageKey) as? DB_Message else {
            return
        }
        dbMessage.fileMetaInfo.thumbnailFilePath = filePath
        let alHandler = ALDBHandler.sharedInstance()
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }
}

extension ALKSVMessagePhotoDownloader : ALKHTTPManagerDownloadDelegate{
    func dataDownloaded(task: ALKDownloadTask) {
        guard let identifier = task.identifier, !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            return
        }
        DispatchQueue.main.async {
            let total = task.totalBytesExpectedToDownload
            let progress = task.totalBytesDownloaded.degree(outOf: total)
            self.delegate?.didPhotoDownloadProgress(progress: progress, total: total)
        }
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        let _completed:((String?, _ isThumbnail:Bool ,Error?)->()) =  { path, isThumbnail, error in
            DispatchQueue.main.async {
                if self.isCanceled {
                    self.delegate?.didPhotoDownloadCanceled(messageKey:self.messageKey)
                    return
                }else{
                    self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:path, isThumbnail: isThumbnail, error:error)
                }
            }
        }
        
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            _completed(nil, false, task.downloadError)
            return
        }
        
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            _completed(filePath, true, nil)
            self.updateThumbnailPath(identifier, filePath: filePath)
            return
        }
        
        //check can open or not
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(filePath).path
        let originalPath = task.urlString ?? ""
        if UIImage(contentsOfFile: path) == nil {
                 if UIImage(contentsOfFile: originalPath) != nil {
                     ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished with wrong file format,but web url work, filePath:\(filePath ), msg_key:\(identifier), webPath:\(originalPath)")
                 }else{
                     ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished with wrong file format, filePath:\(filePath ), msg_key:\(identifier), webPath:\(originalPath)")
                 }
                 

            try? FileManager.default.removeItem(atPath: path)
            _completed(nil, false, nil)
            return
        }
        //save file and remove item
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        _completed(filePath, false, nil)
    }
}
