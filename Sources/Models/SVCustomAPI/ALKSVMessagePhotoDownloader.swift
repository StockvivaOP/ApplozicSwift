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
    func didPhotoDownloadFinished(messageKey:String?, path:String?, error:Error?)
}

open class ALKSVMessagePhotoDownloader : NSObject {
    
    open var delegate:ALKSVMessagePhotoDownloaderDelegate?
    open var messageKey:String?
    open var photoName:String?
    open var photoSize:Int = 0
    open var photoBlobKey:String?
    
    private var isCanceled:Bool = false
    
    // MARK: - Initializer
    public override init() {
        super.init()
    }
    
    open func downloadPhoto(){
        guard let _messageKey = self.messageKey, let _photoBlobKey = self.photoBlobKey else {
            self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:nil, error:nil)
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadPhoto error with msg_key:\(self.messageKey ?? "nil"), photoBlobKey:\(self.photoBlobKey ?? "nil")")
            return
        }
        self.isCanceled = false
        ALMessageClientService().downloadImageUrl(_photoBlobKey) { (fileUrl, error) in
            if self.isCanceled {
                self.delegate?.didPhotoDownloadCanceled(messageKey:self.messageKey)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadPhoto with canceled, fileUrl:\(fileUrl ?? "nil"), msg_key:\(self.messageKey ?? "nil"), photoBlobKey:\(self.photoBlobKey ?? "nil")")
                return
            }
            guard error == nil, let _fileUrl = fileUrl else {
                self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:nil, error:error)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader downloadPhoto with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), fileUrl:\(fileUrl ?? "nil"), msg_key:\(self.messageKey ?? "nil"), photoBlobKey:\(self.photoBlobKey ?? "nil")")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: _fileUrl, fileName: self.photoName)
            task.identifier = _messageKey
            task.totalBytesExpectedToDownload = Int64(self.photoSize)
            httpManager.downloadAttachment(task: task)
        }
    }
    
    open func cancelDownload(){
        self.isCanceled = true
    }
}

extension ALKSVMessagePhotoDownloader : ALKHTTPManagerDownloadDelegate{
    func dataDownloaded(task: ALKDownloadTask) {
        //none action
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        let _completed:((String?, Error?)->()) =  { path, error in
            DispatchQueue.main.async {
                if self.isCanceled {
                    self.delegate?.didPhotoDownloadCanceled(messageKey:self.messageKey)
                    return
                }else{
                    self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:path, error:error)
                }
            }
        }
        
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            _completed(nil, task.downloadError)
            return
        }
        
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            _completed(filePath, nil)
            return
        }
        
        //check can open or not
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(filePath).path
        if UIImage(contentsOfFile: path) == nil {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - ALKSVMessagePhotoDownloader - dataDownloadingFinished with wrong file format, filePath:\(filePath ), msg_key:\(identifier)")
            try? FileManager.default.removeItem(atPath: path)
            _completed(nil, nil)
            return
        }
        //save file and remove item
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        _completed(filePath, nil)
    }
}
