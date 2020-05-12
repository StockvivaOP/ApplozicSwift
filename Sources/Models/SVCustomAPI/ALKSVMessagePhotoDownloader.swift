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
            return
        }
        self.isCanceled = false
        ALMessageClientService().downloadImageUrl(_photoBlobKey) { (fileUrl, error) in
            if self.isCanceled {
                self.delegate?.didPhotoDownloadCanceled(messageKey:self.messageKey)
                return
            }
            guard error == nil, let fileUrl = fileUrl else {
                self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:nil, error:error)
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: fileUrl, fileName: self.photoName)
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
                    self.delegate?.didPhotoDownloadFinished(messageKey:self.messageKey, path:nil, error:task.downloadError)
                }
            }
        }
        
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            _completed(nil, task.downloadError)
            return
        }
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            _completed(filePath, nil)
            return
        }
        
        //check can open or not
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = documentsURL.appendingPathComponent(filePath).path
        if UIImage(contentsOfFile: path) == nil {
            try? FileManager.default.removeItem(atPath: path)
            _completed(nil, nil)
            return
        }
        //save file and remove item
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        _completed(filePath, nil)
    }
}
