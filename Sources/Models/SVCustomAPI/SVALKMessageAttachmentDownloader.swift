//
//  SVALKMessageAttachmentDownloader.swift
//  ApplozicSwift
//
//  Created by OldPig Chu on 6/7/2020.
//  Copyright © 2020 Applozic. All rights reserved.
//

import Foundation
import Applozic

public protocol ALKSVMessageAttachmentDownloaderDelegate: class {
    func didAttachmentDownloadCanceled(messageKey:String?)
    func didAttachmentDownloadProgress(progress:Double, total:Int64)
    func didAttachmentDownloadFinished(messageKey:String?, path:String?, error:Error?)
}

open class SVALKMessageAttachmentDownloader : NSObject {
    
    open var delegate:ALKSVMessageAttachmentDownloaderDelegate?
    open var messageKey:String?
    open var attachmentName:String?
    open var attachmentSize:Int = 0
    open var attachmentBlobKey:String?
    
    private var isCanceled:Bool = false
    
    // MARK: - Initializer
    public override init() {
        super.init()
    }
    
    open func downloadAttachment(){
        let _attblobKey:String? = self.attachmentBlobKey
        guard let _messageKey = self.messageKey, let _blobKey = _attblobKey else {
            self.delegate?.didAttachmentDownloadFinished(messageKey:self.messageKey, path:nil, error:nil)
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - SVALKMessageAttachmentDownloader downloadAttachment error with msg_key:\(self.messageKey ?? "nil"), blobKey:\(_attblobKey ?? "nil")")
            return
        }
        self.isCanceled = false
        
        ALMessageClientService().downloadImageUrl(_blobKey) { (fileUrl, error) in
            if self.isCanceled {
                self.delegate?.didAttachmentDownloadCanceled(messageKey:_messageKey)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - SVALKMessageAttachmentDownloader downloadAttachment with canceled, fileUrl:\(fileUrl ?? "nil"), msg_key:\(_messageKey), photoBlobKey:\(_blobKey)")
                return
            }
            guard error == nil, let _fileUrl = fileUrl else {
                self.delegate?.didAttachmentDownloadFinished(messageKey:_messageKey, path:nil, error:error)
                ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - SVALKMessageAttachmentDownloader downloadAttachment with error:\(error ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), fileUrl:\(fileUrl ?? "nil"), msg_key:\(_messageKey), photoBlobKey:\(_blobKey)")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: _fileUrl, fileName: self.attachmentName)
            task.identifier = _messageKey
            task.totalBytesExpectedToDownload = Int64(self.attachmentSize)
            httpManager.downloadAttachment(task: task)
        }
    }
    
    open func cancelDownload(){
        self.isCanceled = true
    }
}

extension SVALKMessageAttachmentDownloader : ALKHTTPManagerDownloadDelegate{
    func dataDownloaded(task: ALKDownloadTask) {
        DispatchQueue.main.async {
            let total = task.totalBytesExpectedToDownload
            let progress = task.totalBytesDownloaded.degree(outOf: total)
            self.delegate?.didAttachmentDownloadProgress(progress: progress, total: total)
        }
    }
    
    func dataDownloadingFinished(task: ALKDownloadTask) {
        let _completed:((String?,Error?)->()) =  { path, error in
            DispatchQueue.main.async {
                if self.isCanceled {
                    self.delegate?.didAttachmentDownloadCanceled(messageKey:self.messageKey)
                    return
                }else{
                    self.delegate?.didAttachmentDownloadFinished(messageKey:self.messageKey, path:path, error:error)
                }
            }
        }
        
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .error, message: "chatgroup - fileDownload - SVALKMessageAttachmentDownloader - dataDownloadingFinished with error:\(task.downloadError ?? NSError(domain: "none", code: -1, userInfo: ["localizedDescription" : "none error got"])), filePath:\(task.filePath ?? "nil"), msg_key:\(task.identifier ?? "")")
            _completed(nil, task.downloadError)
            return
        }
        ALKConfiguration.delegateSystemInfoRequestDelegate?.logging(type: .debug, message: "chatgroup - fileDownload - SVALKMessageAttachmentDownloader - dataDownloadingFinished downloaded, filePath:\(filePath ), msg_key:\(identifier)")
        
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        _completed(filePath, nil)
    }
}
